"""Supabase Storage adapter (SIH26002 P1 — real photo handling).

Server-side ONLY: uses SUPABASE_SERVICE_ROLE_KEY which must never leave the
backend (architecture AX-2/AX-3). The browser never talks to Storage directly;
it uploads through the API, which validates bytes (magic sniffing in
app/core/uploads.py), mints a traversal-proof path, and stores into a PRIVATE
bucket. Reads are short-lived signed URLs issued only after permission checks.

Config-gated: when the service key is absent the adapter reports unconfigured
and callers fail with an explicit error — the rest of NER-SHIELD keeps working
(field reports continue to function without photos, as before).
"""
import logging

import httpx

from app.config import get_settings

log = logging.getLogger("ner-shield.storage")

_SIGNED_URL_TTL_S = 600


class StorageUnavailable(Exception):
    """Storage not configured or upstream failure — caller maps to HTTP 503."""


def configured() -> bool:
    s = get_settings()
    return bool(s.SUPABASE_URL and s.SUPABASE_SERVICE_ROLE_KEY)


def _headers(service_key: str) -> dict:
    return {"Authorization": f"Bearer {service_key}",
            "apikey": service_key}


async def upload_object(bucket: str, path: str, data: bytes,
                        content_type: str) -> None:
    """PUT one object into a private bucket. Path is server-minted only."""
    s = get_settings()
    if not (s.SUPABASE_URL and s.SUPABASE_SERVICE_ROLE_KEY):
        raise StorageUnavailable("object storage not configured")
    url = f"{s.SUPABASE_URL.rstrip('/')}/storage/v1/object/{bucket}/{path}"
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(
                url, content=data,
                headers={**_headers(s.SUPABASE_SERVICE_ROLE_KEY),
                         "Content-Type": content_type,
                         "x-upsert": "false"})
        # 200 = created; 409/400 handled as failure (we never overwrite)
        if resp.status_code not in (200, 201):
            log.warning("storage upload rejected: %s %s",
                        resp.status_code, resp.text[:200])
            raise StorageUnavailable(f"storage upload failed "
                                     f"(HTTP {resp.status_code})")
    except httpx.HTTPError as exc:
        log.warning("storage unreachable: %s", str(exc)[:200])
        raise StorageUnavailable("storage unreachable") from exc


async def create_signed_url(bucket: str, path: str,
                            ttl_s: int = _SIGNED_URL_TTL_S) -> str:
    """Short-lived signed URL for an authorized viewer."""
    s = get_settings()
    if not (s.SUPABASE_URL and s.SUPABASE_SERVICE_ROLE_KEY):
        raise StorageUnavailable("object storage not configured")
    url = (f"{s.SUPABASE_URL.rstrip('/')}"
           f"/storage/v1/object/sign/{bucket}/{path}")
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(
                url, json={"expiresIn": max(30, min(ttl_s, 3600))},
                headers=_headers(s.SUPABASE_SERVICE_ROLE_KEY))
        if resp.status_code != 200:
            raise StorageUnavailable(
                f"signing failed (HTTP {resp.status_code})")
        signed = resp.json().get("signedURL")
        if not signed:
            raise StorageUnavailable("signing returned no URL")
        return f"{s.SUPABASE_URL.rstrip('/')}/storage/v1{signed}"
    except httpx.HTTPError as exc:
        raise StorageUnavailable("storage unreachable") from exc
