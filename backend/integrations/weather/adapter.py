"""Weather adapter. Provider-agnostic: the endpoint/provider/credential come
from configuration ONLY (no hard-coded vendor). Until a provider is authorized
and configured the adapter reports UNAVAILABLE and refuses to fabricate data."""
from integrations.base import BaseAdapter, IntegrationConfig
from integrations.weather.schemas import WeatherObservation

# Default config: disabled + unconfigured. Deployment sets WEATHER_API_ENDPOINT /
# WEATHER_API_KEY_ENV once the source is approved. Nothing here pretends to be live.
DEFAULT_CONFIG = IntegrationConfig(
    name="weather-primary",
    source_type="WEATHER",
    provider="pending-authorization",
    endpoint=None,
    api_key_env="WEATHER_API_KEY",
    enabled=False,
    license_note="Requires government-approved meteorological data license "
                 "before enablement.",
)


class WeatherAdapter(BaseAdapter):
    """Fetches observations; normalize() enforces the WeatherObservation contract.

    Expected upstream shape (documented adapter contract; adjust mapping in a
    thin subclass per provider — never inside the risk engine):
        {"observations": [{"district_code": "...", "rainfall_mm_24h": 12.5,
                           "observed_at": "2026-08-24T06:00:00Z", ...}]}
    """

    async def _fetch_once(self, **params):
        raw = await super()._fetch_once(**params)
        if isinstance(raw, dict):
            return raw.get("observations", [])
        return raw

    def normalize(self, record: dict) -> dict:
        obs = WeatherObservation.model_validate(
            {**record, "source": self.config.provider})
        return obs.model_dump(mode="json")
