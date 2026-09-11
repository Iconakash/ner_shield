"""Satellite imagery adapter — authorized providers only (metadata pipeline).
The adapter ingests scene METADATA + object-storage references; it never
fabricates imagery or claims live coverage without a successful fetch."""
from integrations.base import BaseAdapter, IntegrationConfig
from integrations.satellite.schemas import SatelliteScene

DEFAULT_CONFIG = IntegrationConfig(
    name="satellite-primary",
    source_type="SATELLITE",
    provider="pending-authorization",
    endpoint=None,
    api_key_env="SATELLITE_API_KEY",
    enabled=False,
    rate_limit_per_min=20,
    license_note="Requires imagery-provider license AND storage provisioning "
                 "before enablement.",
)


class SatelliteAdapter(BaseAdapter):
    async def _fetch_once(self, **params):
        raw = await super()._fetch_once(**params)
        if isinstance(raw, dict):
            return raw.get("scenes", [])
        return raw

    def normalize(self, record: dict) -> dict:
        scene = SatelliteScene.model_validate(record)
        return scene.model_dump(mode="json")
