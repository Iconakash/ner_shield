"""Disaster advisory adapter. Multi-authority by design: each approved authority
gets its own adapter instance/config; all normalize into DisasterAdvisory.
Never assume one national provider will always exist."""
from integrations.base import BaseAdapter, IntegrationConfig
from integrations.disaster.schemas import DisasterAdvisory

DEFAULT_CONFIG = IntegrationConfig(
    name="disaster-primary",
    source_type="DISASTER",
    provider="pending-authorization",
    endpoint=None,
    api_key_env="DISASTER_API_KEY",
    enabled=False,
    license_note="Requires authorization from the responsible disaster-management "
                 "authority before enablement.",
)


class DisasterAdapter(BaseAdapter):
    async def _fetch_once(self, **params):
        raw = await super()._fetch_once(**params)
        if isinstance(raw, dict):
            return raw.get("advisories", [])
        return raw

    def normalize(self, record: dict) -> dict:
        adv = DisasterAdvisory.model_validate(record)
        return adv.model_dump(mode="json")
