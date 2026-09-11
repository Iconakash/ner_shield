"""Copernicus Data Space Ecosystem (Sentinel) adapter — master upgrade §4.

Metadata-only ingestion (project rule §28/§13): scene METADATA + storage
references; imagery never enters PostgreSQL and is never fabricated.

Endpoints below are the OFFICIAL documented CDSE interfaces:
  * OAuth2 client-credentials token:
      https://identity.dataspace.copernicus.eu/auth/realms/CDSE/protocol/openid-connect/token
  * OData product catalogue:
      https://catalogue.dataspace.copernicus.eu/odata/v1 (entity set `Products`)
Both are overridable via configuration. Client credentials NEVER leave the
server process; they must not be baked into frontend JavaScript or the DB.
"""
import logging
import time

import httpx

from integrations.base import BaseAdapter, IntegrationConfig, SourceUnavailable

logger = logging.getLogger("ner-shield.integrations.copernicus")

DEFAULT_TOKEN_URL = ("https://identity.dataspace.copernicus.eu/auth/realms/"
                     "CDSE/protocol/openid-connect/token")

DEFAULT_CONFIG = IntegrationConfig(
    name="satellite-copernicus",
    source_type="SATELLITE",
    provider="COPERNICUS",
    endpoint=None,               # OData catalogue base URL when configured
    api_key_env=None,            # uses COPERNICUS_CLIENT_ID/_SECRET instead
    enabled=False,
    rate_limit_per_min=20,
    license_note="Sentinel data is open under the Copernicus/EU Space "
                 "Programme licence; attribution required. Metadata pipeline "
                 "only.",
)

# env names holding credentials (read at fetch time, never logged)
CLIENT_ID_ENV = "COPERNICUS_CLIENT_ID"
CLIENT_SECRET_ENV = "COPERNICUS_CLIENT_SECRET"


def _bbox_from_geojson(geom):
    """[lon_min, lat_min, lon_max, lat_max] from a GeoJSON Polygon/Multipolygon."""
    if not isinstance(geom, dict):
        return None
    lons: list[float] = []
    lats: list[float] = []

    def walk(node):
        if (isinstance(node, (list, tuple)) and len(node) >= 2
                and isinstance(node[0], (int, float))
                and isinstance(node[1], (int, float))):
            lons.append(float(node[0]))
            lats.append(float(node[1]))
        elif isinstance(node, (list, tuple)):
            for child in node:
                walk(child)

    walk(geom.get("coordinates"))
    if not lons:
        return None
    return [min(lons), min(lats), max(lons), max(lats)]


class _CopernicusBase(BaseAdapter):
    """Credential + transport plumbing shared by the concrete provider below."""

    def __init__(self, config: IntegrationConfig,
                 token_url: str | None = None,
                 client_id: str | None = None,
                 client_secret: str | None = None):
        super().__init__(config)
        self._token_url = token_url or DEFAULT_TOKEN_URL
        self._client_id = client_id
        self._client_secret = client_secret
        self._token: str | None = None
        self._token_expiry_s: float = 0.0

    @property
    def is_configured(self) -> bool:
        import os
        return bool(self.config.endpoint) and bool(
            self._client_id or os.environ.get(CLIENT_ID_ENV))

    async def _access_token(self) -> str:
        """OAuth2 client-credentials grant with in-memory caching."""
        import os

        now = time.monotonic()
        if self._token and now < self._token_expiry_s - 60:
            return self._token
        cid = self._client_id or os.environ.get(CLIENT_ID_ENV)
        csec = self._client_secret or os.environ.get(CLIENT_SECRET_ENV)
        if not cid or not csec:
            raise SourceUnavailable(
                f"{self.config.name}: {CLIENT_ID_ENV}/{CLIENT_SECRET_ENV} not set")
        async with httpx.AsyncClient(timeout=self.config.timeout_s) as client:
            resp = await client.post(self._token_url,
                                     data={"grant_type": "client_credentials"})
            if resp.status_code in (401, 403):
                raise SourceUnavailable(
                    f"{self.config.name}: credential rejected ({resp.status_code})")
            resp.raise_for_status()
            payload = resp.json()
        token = payload.get("access_token")
        expires_in = float(payload.get("expires_in", 300))
        if not token:
            raise SourceUnavailable(f"{self.config.name}: no access_token in grant")
        self._token = token
        self._token_expiry_s = time.monotonic() + expires_in
        return token


class CopernicusProvider(_CopernicusBase):
    """OData catalogue search -> normalized SatelliteScene metadata rows."""

    async def _fetch_once(self, **params):
        token = await self._access_token()
        base = (self.config.endpoint or "").rstrip("/")
        url = f"{base}/Products"          # documented OData entity set
        filt_parts = []
        collection = params.get("collection")
        if collection:
            filt_parts.append(f"Collection/Name eq '{collection}'")
        top = min(int(params.get("top", 50)), 100)
        odata = {"$top": str(top), "$orderby": "ContentDate/Start desc"}
        if filt_parts:
            odata["$filter"] = " and ".join(filt_parts)
        headers = {"Authorization": f"Bearer {token}",
                   "User-Agent": "NER-SHIELD/1.0"}
        async with httpx.AsyncClient(timeout=self.config.timeout_s) as client:
            resp = await client.get(url, params=odata, headers=headers)
            if resp.status_code == 429:
                raise RuntimeError("copernicus rate limited (429)")
            resp.raise_for_status()
            payload = resp.json()
        value = payload.get("value") if isinstance(payload, dict) else payload
        if not isinstance(value, list):
            raise ValueError("unexpected catalogue payload shape")
        kept, dropped = [], 0
        for item in value:
            if (isinstance(item, dict) and item.get("Id")
                    and (item.get("ContentDate") or {}).get("Start")):
                kept.append(item)
            else:
                dropped += 1
        if dropped:
            logger.warning("copernicus items quarantined (missing Id/acquisition)",
                           extra={"data": {"dropped": dropped, "kept": len(kept)}})
        return kept

    def normalize(self, record: dict) -> dict:
        from datetime import datetime, timezone

        from integrations.satellite.schemas import SatelliteScene

        content_date = record.get("ContentDate") or {}
        scene = SatelliteScene.model_validate({
            "external_id": str(record["Id"]),
            "provider": self.config.provider,
            "acquired_at": content_date["Start"],
            "coverage_bbox": _bbox_from_geojson(record.get("GeoFootprint")),
            "storage_path": None,       # metadata pipeline only (rule §28)
            "source_url": f"{(self.config.endpoint or '').rstrip('/')}"
                          f"/Products({record['Id']})/$value",
        })
        out = scene.model_dump(mode="json")
        out["received_at"] = datetime.now(timezone.utc).isoformat()
        return out