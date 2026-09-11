"""NDMA SACHET adapter (master upgrade §5) — official disaster alerts.

Normalizes SACHET/Common Alerting Protocol-style records into the project's
existing internal DisasterAdvisory schema. Rule 28: no undocumented endpoint is
fabricated — the deployment configures SACHET_BASE_URL once an authorized
machine-readable feed is granted; until then the adapter reports UNAVAILABLE.

Documented SACHET alert levels (per NDMA's common alerting protocol) are mapped
onto the internal constrained severity scale; documented hazard categories are
mapped onto the internal hazard enum. Unmappable values are quarantined, never
silently coerced.
"""
import logging

from integrations.base import BaseAdapter, IntegrationConfig
from integrations.disaster.adapter import DisasterAdapter
from integrations.disaster.schemas import DisasterAdvisory

logger = logging.getLogger("ner-shield.integrations.sachet")

# SACHET/CAP alert levels -> internal severity (documented public taxonomy)
SEVERITY_MAP = {
    "ADVISORY": "LOW",
    "WATCH": "MEDIUM",
    "ALERT": "HIGH",
    "WARNING": "CRITICAL",
    # direct internal values pass through
    "INFO": "INFO", "LOW": "LOW", "MEDIUM": "MEDIUM",
    "HIGH": "HIGH", "CRITICAL": "CRITICAL",
}

# SACHET hazard categories -> internal hazard enum
HAZARD_MAP = {
    "FLOOD": "FLOOD",
    "HEAVY_RAINFALL": "FLOOD",
    "HEAVY RAINFALL": "FLOOD",
    "RAINFALL": "FLOOD",
    "CYCLONE": "CYCLONE",
    "LANDSLIDE": "LANDSLIDE",
    "EARTHQUAKE": "EARTHQUAKE",
    "THUNDERSTORM": "STORM",
    "LIGHTNING": "OTHER",
    "FOREST_FIRE": "OTHER",
    "FOREST FIRE": "OTHER",
}

DEFAULT_CONFIG = IntegrationConfig(
    name="disaster-sachet",
    source_type="DISASTER",
    provider="NDMA-SACHET",
    endpoint=None,
    api_key_env=None,
    enabled=False,
    rate_limit_per_min=20,
    license_note="Official national disaster alerts; requires authorization/"
                 "data-sharing confirmation from NDMA before enablement.",
)


class SachetProvider(DisasterAdapter):
    """Maps SACHET alerts onto DisasterAdvisory; drops un-mappable rows."""

    async def _fetch_once(self, **params):
        # Call the BASE transport, not DisasterAdapter._fetch_once: the
        # parent's unwrap only knows the "advisories" envelope and would
        # collapse SACHET's documented CAP envelopes (alerts/items/value)
        # into an empty list before this class ever saw them (defect found
        # by the Phase 8 mocked-response test — CAP payloads returned zero
        # advisories). Unwrapping happens HERE, across all keys below.
        raw = await BaseAdapter._fetch_once(self, **params)
        if isinstance(raw, dict):
            for key in ("advisories", "alerts", "items", "value"):
                if isinstance(raw.get(key), list):
                    raw = raw[key]
                    break
            else:
                raw = [raw]
        kept, dropped = [], 0
        for rec in raw:
            try:
                DisasterAdvisory.model_validate(_map_record(rec))
                kept.append(rec)
            except Exception:  # noqa: BLE001 — quarantine, never guess
                dropped += 1
        if dropped:
            logger.warning("sachet records quarantined (unmappable/invalid)",
                           extra={"data": {"dropped": dropped,
                                           "kept": len(kept)}})
        return kept

    def normalize(self, record: dict) -> dict:
        adv = DisasterAdvisory.model_validate(_map_record(record))
        out = adv.model_dump(mode="json")
        out["authority"] = adv.authority or self.config.provider
        return out


def _map_record(rec: dict) -> dict:
    rec = dict(rec)
    if "severity" in rec and rec["severity"]:
        mapped = SEVERITY_MAP.get(str(rec["severity"]).upper())
        if mapped is None:
            raise ValueError(f"unmappable SACHET severity {rec['severity']!r}")
        rec["severity"] = mapped
    if "hazard" in rec and rec["hazard"]:
        mapped = HAZARD_MAP.get(str(rec["hazard"]).upper())
        if mapped is None:
            raise ValueError(f"unmappable SACHET hazard {rec['hazard']!r}")
        rec["hazard"] = mapped
    rec.setdefault("authority", "NDMA-SACHET")
    return rec