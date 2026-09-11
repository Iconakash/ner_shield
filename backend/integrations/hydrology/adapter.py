"""CWC — Central Water Commission hydrology provider (master upgrade §6).

Rule 28 compliance: CWC publishes river-level/flood information through its own
official channels but exposes no open, documented public bulk API that this
repository could rely on. NO endpoint is fabricated. The deployment supplies an
authorized data-sharing endpoint via CWC_BASE_URL (+ CWC_API_KEY when required);
until then this provider reports UNAVAILABLE and never invents readings.

Expected upstream shape (documented adapter contract for the authorized feed):
    {"readings": [{"station_code": "...", "water_level_m": 84.2,
                   "level_trend": "RISING", "observed_at": "...", ...}]}
"""
from integrations.base import BaseAdapter, IntegrationConfig

DEFAULT_CONFIG = IntegrationConfig(
    name="cwc-primary",
    source_type="HYDROLOGY",
    provider="CWC",
    endpoint=None,
    api_key_env="CWC_API_KEY",
    enabled=False,
    rate_limit_per_min=20,
    license_note="Official Government of India hydrological data; requires a "
                 "CWC data-sharing authorization before enablement.",
)

VALID_TRENDS = ("RISING", "FALLING", "STEADY", "UNKNOWN")


class CWCProvider(BaseAdapter):
    async def _fetch_once(self, **params):
        raw = await super()._fetch_once(**params)
        if isinstance(raw, dict):
            for key in ("readings", "observations", "data"):
                if isinstance(raw.get(key), list):
                    return raw[key]
            return [raw]
        return raw

    def normalize(self, record: dict) -> dict:
        from integrations.hydrology.schemas import RiverObservation

        obs = RiverObservation.model_validate(
            {**record, "source": self.config.provider})
        return obs.model_dump(mode="json")