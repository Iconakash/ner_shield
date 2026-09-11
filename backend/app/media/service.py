"""Field-report photo media (SIH26002 P1).

Upload path (all validation server-side; the client is never trusted):

    FIELD OFFICER -> POST /field/reports/{id}/media  (multipart image)
        -> report ownership/scope check
        -> core/uploads.validate_upload (size/extension/magic bytes)
        -> server-minted path field-reports/{report_id}/{uuid}.{ext}
        -> Supabase Storage PRIVATE bucket
        -> field_report_media row (sha256 dedupe => idempotent retries)

View path:
    GET /field/reports/{id}/media            metadata list
    GET /field/reports/{id}/media/{mid}/url  short-lived signed URL
                                             (owner or VIEW_INCIDENTS only)

Offline compatibility: the existing offline flow submits the report first and
queues the photo; media attaches whenever connectivity returns. Duplicate
uploads of identical bytes return the original row (sha256 match).
"""
import hashlib
import uuid

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from integrations.storage import supabase_storage as storage

BUCKET_PROPERTY = "SUPABASE_STORAGE_BUCKET"
DEFAULT_BUCKET = "field-reports"


def bucket_name() -> str:
    return getattr(get_settings(), BUCKET_PROPERTY, DEFAULT_BUCKET) \
        or DEFAULT_BUCKET


def mint_storage_path(report_id: str, ext: str) -> str:
    """Traversal-proof path — NO user-supplied component survives."""
    return f"field-reports/{report_id}/{uuid.uuid4().hex}.{ext}"


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class MediaError(Exception):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code, self.message = code, message


async def _report_for_access(db: AsyncSession, report_id: str,
                             user_id: str | None):
    return (await db.execute(text("""
        select fr.id::text as id, fr.reported_by::text as reported_by,
               fr.state_code, fr.district_code, fr.status::text as status
        from field_reports fr where fr.id = cast(:i as uuid)
    """), {"i": report_id})).mappings().first()


async def upload_media(db: AsyncSession, *, report_id: str,
                       user_id: str, filename: str | None,
                       content_type: str | None, data: bytes,
                       has_view_incidents: bool = False) -> dict:
    """Validate + store + persist one photo for an existing report."""
    from app.core.errors import NotFound
    rep = await _report_for_access(db, report_id, user_id)
    if rep is None:
        raise NotFound("report not found")
    if rep["reported_by"] != user_id and not has_view_incidents:
        raise MediaError("FORBIDDEN", "not your report")

    # duplicate retry: same bytes already attached to this report?
    digest = sha256_hex(data)
    dup = (await db.execute(text("""
        select id::text as id, storage_path, mime_type, byte_size
        from field_report_media
        where report_id = cast(:r as uuid) and sha256 = :h
        limit 1
    """), {"r": report_id, "h": digest})).mappings().first()
    if dup is not None:
        return {**dict(dup), "deduplicated": True}

    # hardened validation (size / extension / content-type / magic bytes)
    from app.core.uploads import UploadRejected, validate_upload
    try:
        stored_name, kind = validate_upload(filename=filename or "upload.jpg",
                                            content_type=content_type,
                                            data=data)
    except UploadRejected as exc:
        raise MediaError("UPLOAD_REJECTED", exc.reason) from exc

    ext = stored_name.rsplit(".", 1)[-1].lower()
    path = mint_storage_path(report_id, ext)
    try:
        await storage.upload_object(bucket_name(), path, data,
                                    content_type or f"image/{ext}")
    except storage.StorageUnavailable as exc:
        raise MediaError("STORAGE_UNAVAILABLE", str(exc)) from exc

    mime = content_type if content_type in ("image/jpeg", "image/png",
                                            "image/webp") else f"image/{ext}"
    row = (await db.execute(text("""
        insert into field_report_media (report_id, storage_path, mime_type,
                                        byte_size, sha256, uploaded_by)
        values (cast(:r as uuid), :p, :m, :b, :h, cast(:u as uuid))
        returning id::text as id, storage_path, mime_type, byte_size,
                  created_at
    """), {"r": report_id, "p": path, "m": mime, "b": len(data),
           "h": digest, "u": user_id})).mappings().first()

    # keep legacy photo_ref meaningful: first media wins if none set
    await db.execute(text("""
        update field_reports set photo_ref = :p
        where id = cast(:r as uuid)
          and (photo_ref is null or photo_ref like 'queued:%')
    """), {"p": path, "r": report_id})
    return dict(row)


async def list_media(db: AsyncSession, report_id: str) -> list[dict]:
    rows = (await db.execute(text("""
        select id::text as id, storage_path, mime_type, byte_size, created_at
        from field_report_media where report_id = cast(:r as uuid)
        order by created_at
    """), {"r": report_id})).mappings().all()
    return [dict(r) for r in rows]


async def signed_url_for(db: AsyncSession, *, report_id: str,
                         media_id: str) -> str:
    from app.core.errors import NotFound
    row = (await db.execute(text("""
        select storage_path from field_report_media
        where id = cast(:m as uuid) and report_id = cast(:r as uuid)
    """), {"m": media_id, "r": report_id})).mappings().first()
    if row is None:
        raise NotFound("media not found")
    return await storage.create_signed_url(bucket_name(), row["storage_path"])
