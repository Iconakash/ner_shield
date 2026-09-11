# -*- coding: utf-8 -*-
"""Multilingual service (Phase 17 · FR-C15).

Pure, DB-free helpers. Storage stays CANONICAL ENGLISH; localization happens
at read time so no schema change is forced on existing tables.

Language resolution order (FR-C15.2):
    explicit ?lang=  >  Accept-Language header  >  profiles.language  >  "en"
Every candidate passes normalize_lang(); unsupported values fall back to "en"
(never a hard error — an untranslated surface must still be usable).
"""
from typing import Any, Mapping

from app.i18n.catalog import CATALOGS

DEFAULT_LANG = "en"
FALLBACK_LANG = "en"

SUPPORTED_LANGUAGES: dict[str, dict[str, str]] = {
    "en": {"name": "English", "native_name": "English"},
    "hi": {"name": "Hindi", "native_name": "हिन्दी"},
    "as": {"name": "Assamese", "native_name": "অসমীয়া"},  # selected NER language
    # SIH26002 P8: Manipuri/Meitei — DEMO translations (romanized Meiteilon),
    # pending native-speaker sign-off; surfaced honestly via `demo` flag.
    "mni": {"name": "Manipuri", "native_name": "Meiteilon",
            "demo": True},
}


def is_supported(lang: str | None) -> bool:
    return bool(lang) and lang in SUPPORTED_LANGUAGES


def normalize_lang(raw: str | None) -> str:
    """"hi-IN" -> "hi" · "AS" -> "as" · "as;q=0.9" -> "as" · junk -> en."""
    if not raw:
        return DEFAULT_LANG
    code = (str(raw).strip().split(",")[0].split("-")[0]
            .split(";")[0].strip().lower())
    return code if code in SUPPORTED_LANGUAGES else DEFAULT_LANG


def t(lang: str, key: str, **kwargs: Any) -> str:
    """Translate `key` into `lang`, falling back xx -> en -> key itself.

    {placeholders} interpolate from kwargs; unknown placeholders are left
    visible rather than raising (operational text must never crash a read).
    """
    lang = normalize_lang(lang)
    text = CATALOGS.get(lang, {}).get(key)
    if text is None:
        text = CATALOGS[FALLBACK_LANG].get(key)
    if text is None:
        return key
    if kwargs:
        try:
            return text.format(**kwargs)
        except (KeyError, IndexError, ValueError):
            return text
    return text


def _first_supported(*candidates: str | None) -> str:
    for c in candidates:
        if c:
            code = (str(c).strip().split(",")[0].split("-")[0]
                    .split(";")[0].strip().lower())
            if code in SUPPORTED_LANGUAGES:
                return code
    return DEFAULT_LANG


def resolve_lang(request: Any = None, principal: Any = None,
                 explicit: str | None = None) -> str:
    """?lang= > Accept-Language > principal.language > default.

    `request` is duck-typed (needs .query_params / .headers Mappings), so this
    stays unit-testable without FastAPI machinery.
    """
    query_lang = header_lang = profile_lang = None
    if request is not None:
        qp = getattr(request, "query_params", {}) or {}
        query_lang = qp.get("lang")
        headers = getattr(request, "headers", {}) or {}
        raw_header = (headers.get("accept-language")
                      or headers.get("Accept-Language"))
        if raw_header:
            # first entry of the q-ordered list wins; quality params ignored
            header_lang = str(raw_header).split(",")[0]
        profile_lang = getattr(principal, "language", None)
    elif explicit:
        query_lang = explicit
    return _first_supported(query_lang, header_lang, profile_lang)


# ------------------------------------------------------------- alerts (C11/C15)

ALERT_TYPES = ("ROAD_WARNING", "CRITICAL_SHIPMENT", "REGIONAL_SUPPLY_CRISIS",
               "DISRUPTION_PREDICTED", "SHORTAGE_PREDICTED", "IMPACT_ALERT",
               "SYSTEM")
LEVELS = ("INFO", "WARNING", "HIGH", "CRITICAL")

def localized_alert(row: Mapping[str, Any], lang: str) -> dict[str, Any]:
    """Read-side rendering: add *_lang fields to an inbox row.

    Never mutates or hides the canonical English fields — operators can always
    compare against the source of truth.
    """
    atype = row.get("alert_type") or "SYSTEM"
    level = row.get("level") or "INFO"
    payload = row.get("payload") if isinstance(row.get("payload"), dict) else {}
    incident_type_key = payload.get("incident_type")

    out: dict[str, Any] = {
        "level_lang": t(lang, f"alerts.level.{level}"),
        "type_lang": t(lang, f"alerts.type.{atype}"),
    }
    has_title_tmpl = f"alerts.title.{atype}" in CATALOGS[FALLBACK_LANG]
    has_msg_tmpl = f"alerts.message.{atype}" in CATALOGS[FALLBACK_LANG]

    kwargs = {
        "district": row.get("district_code") or "",
        "level": out["level_lang"],
        "incident_type": (t(lang, f"field.incident_type.{incident_type_key}")
                          if incident_type_key else ""),
        "message": row.get("message") or "",
    }
    out["title_lang"] = (t(lang, f"alerts.title.{atype}", **kwargs)
                         if has_title_tmpl else (row.get("title") or ""))
    out["message_lang"] = (t(lang, f"alerts.message.{atype}", **kwargs)
                           if has_msg_tmpl else (row.get("message") or ""))

    # EMERGENCY INSTRUCTION: actionable guidance keyed by incident type.
    emergency_key = (f"alerts.emergency.{incident_type_key}"
                     if incident_type_key in ("LANDSLIDE", "FLOOD",
                                              "ROAD_DAMAGE",
                                              "TRAFFIC_BLOCKAGE",
                                              "BRIDGE_PROBLEM")
                     else "alerts.emergency.GENERIC")
    out["emergency_instruction"] = t(lang, emergency_key)

    status = row.get("status")
    if status:
        out["status_lang"] = t(lang, f"alerts.status.{status}")
    return out


# ------------------------------------------------------- field form (C12 forms)

INCIDENT_TYPES = ("LANDSLIDE", "FLOOD", "ROAD_DAMAGE", "TRAFFIC_BLOCKAGE",
                  "BRIDGE_PROBLEM", "OTHER")
SEVERITIES = ("LOW", "MEDIUM", "HIGH", "CRITICAL")


def field_form_schema(lang: str) -> dict[str, Any]:
    """Translated incident-report form + field instructions (FR-C15.1)."""
    lang = normalize_lang(lang)
    return {
        "language": lang,
        "title": t(lang, "field.form.title"),
        "fields": [
            {"id": "token", "label": t(lang, "field.form.token"),
             "type": "password"},
            {"id": "type", "label": t(lang, "field.form.type"),
             "type": "select",
             "options": [{"value": v,
                          "label": t(lang, f"field.incident_type.{v}")}
                         for v in INCIDENT_TYPES]},
            {"id": "severity", "label": t(lang, "field.form.severity"),
             "type": "select",
             "options": [{"value": v,
                          "label": t(lang, f"field.severity.{v}")}
                         for v in SEVERITIES]},
            {"id": "photo", "label": t(lang, "field.form.photo"),
             "type": "file"},
            {"id": "description",
             "label": t(lang, "field.form.description"),
             "type": "textarea"},
        ],
        "instructions": {
            "gps": t(lang, "field.instruction.gps"),
            "photo": t(lang, "field.instruction.photo"),
            "offline": t(lang, "field.instruction.offline"),
        },
        "submit_label": t(lang, "field.form.submit"),
        "messages": {
            "error_token": t(lang, "field.error.token"),
            "error_gps": t(lang, "field.error.gps"),
        },
    }


# ----------------------------------------------- supply recommendations (C07)

SUPPLY_ACTIONS = ("PRE_POSITION", "ACCELERATE_INCOMING", "MONITOR_CLOSELY",
                  "MONITOR")


def localize_recommendation(action: str, lang: str) -> str:
    return t(normalize_lang(lang), f"supply.action.{action}")


def localize_demand_label(label: str, lang: str) -> str:
    return t(normalize_lang(lang), f"supply.demand.{label}")


def localize_supply_prediction(pred: Mapping[str, Any],
                               lang: str) -> dict[str, Any]:
    """Adds human-readable recommendation/demand text to a prediction row."""
    lang = normalize_lang(lang)
    out = dict(pred)
    if pred.get("recommended_action"):
        out["recommended_action_lang"] = localize_recommendation(
            pred["recommended_action"], lang)
    if pred.get("demand_label"):
        out["demand_label_lang"] = localize_demand_label(
            pred["demand_label"], lang)
    return out

