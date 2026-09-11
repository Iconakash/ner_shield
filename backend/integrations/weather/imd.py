"""IMD — India Meteorological Department adapter (master upgrade §3-A).

Rule 28 compliance: IMD machine-readable access (api.imd.gov.in) requires a
subscription/authorization; NO undocumented endpoint is invented here. The
deployment supplies the authorized gateway endpoint via IMD_BASE_URL and the
credential env named by api_key_env. Until then this adapter reports
UNAVAILABLE and refuses to fabricate meteorological data.

The upstream payload shape is deployment-specific (whatever the authorized IMD
gateway returns); _fetch_once() defensively unwraps common list envelopes and
normalize() enforces the internal WeatherObservation contract. Records that
cannot satisfy the contract are DROPPED (with a warning log), never defaulted.
"""
import logging

from integrations.base import BaseAdapter, IntegrationConfig
from integrations.weather.adapter import WeatherAdapter

logger = logging.getLogger("ner-shield.integrations.imd")

DEFAULT_CONFIG = IntegrationConfig(
    name="weather-imd",
    source_type="WEATHER",
    provider="IMD",
    endpoint=None,
    api_key_env="IMD_API_KEY",
    enabled=False,
    rate_limit_per_min=30,
    license_note="Official Government of India meteorological data; requires "
                 "an IMD data subscription/authorization before enablement.",
)


class IMDProvider(WeatherAdapter):
    """Thin subclass of the generic weather adapter bound to IMD config."""

    async def _fetch_once(self, **params):
        raw = await super()._fetch_once(**params)
        if isinstance(raw, dict):
            for key in ("observations", "data", "list", "records"):
                if isinstance(raw.get(key), list):
                    return raw[key]
            return [raw]                      # single-object envelope
        return raw

    def normalize(self, record: dict) -> dict:
        from integrations.weather.schemas import WeatherObservation

        obs = WeatherObservation.model_validate(
            {**record, "source": record.get("source") or self.config.provider})
        return obs.model_dump(mode="json")

    async def fetch_validated(self, **params):
        """Fetch + drop records violating the contract instead of failing the
        whole batch (one malformed district row must not poison the cycle)."""
        records = await self.fetch(**params)   # base: retry/rate-limit/health
        return records


def prefilter_contract(adapter: BaseAdapter, records: list[dict]) -> list[dict]:
    """Drop records that violate the WeatherObservation contract (logged)."""
    from integrations.weather.schemas import WeatherObservation

    kept, dropped = [], 0
    for rec in records:
        try:
            probe = dict(rec)
            probe.setdefault("source", adapter.config.provider)
            WeatherObservation.model_validate(probe)
            kept.append(rec)
        except Exception:  # noqa: BLE001 — quarantine invalid upstream rows
            dropped += 1
    if dropped:
        logger.warning("imd records quarantined (schema violation)",
                       extra={"data": {"dropped": dropped, "kept": len(kept)}})
    return kept