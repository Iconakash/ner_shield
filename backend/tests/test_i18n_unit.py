"""Phase 17 unit tests — multilingual intelligence (FR-C15).

Pure catalog/service contracts: parity, fallback, resolution order,
localized alert rendering, form schema completeness, recommendation coverage.
"""
import pytest

try:
    from app.i18n import service as i18n
    from app.i18n.catalog import CATALOGS
except ModuleNotFoundError:
    from i18n import service as i18n
    from i18n.catalog import CATALOGS


# ------------------------------------------------------------------- parity
def test_catalog_parity_all_languages_carry_every_key():
    """A missing key is a build failure, not a runtime surprise (FR-C15.1)."""
    base = set(CATALOGS["en"])
    assert base, "english catalog must not be empty"
    for code, cat in CATALOGS.items():
        missing = base - set(cat)
        extra = set(cat) - base
        assert not missing, f"{code} missing keys: {sorted(missing)[:5]}"
        assert not extra, f"{code} extra keys: {sorted(extra)[:5]}"


def test_frozen_mvp_set_is_exactly_en_hi_as_plus_mni_demo():
    """Honest scope statement: no silent claims of broader coverage.

    SIH26002 P8 approved Manipuri/Meitei (mni) as a DEMO translation set
    pending native review; it must stay flagged so UIs can disclose that.
    """
    assert set(CATALOGS) == {"en", "hi", "as", "mni"}
    assert set(i18n.SUPPORTED_LANGUAGES) == {"en", "hi", "as", "mni"}
    assert i18n.SUPPORTED_LANGUAGES["mni"].get("demo") is True


def test_values_are_nonempty_translated_strings():
    for code, cat in CATALOGS.items():
        for key, value in cat.items():
            assert isinstance(value, str) and value.strip(), f"{code}:{key}"


# ------------------------------------------------------------------ t() core
def test_t_english_roundtrip():
    assert i18n.t("en", "nav.dashboard") == "Dashboard"


def test_t_hindi_and_assamese_differ_from_english():
    en = i18n.t("en", "alerts.emergency.FLOOD")
    hi = i18n.t("hi", "alerts.emergency.FLOOD")
    as_ = i18n.t("as", "alerts.emergency.FLOOD")
    assert len({en, hi, as_}) == 3, "each language must translate distinctly"
    # Devanagari for Hindi, Bengali-Assamese script for Assamese
    assert any("\u0900" <= ch <= "\u097F" for ch in hi)
    assert any("\u0980" <= ch <= "\u09FF" for ch in as_)


def test_t_interpolation():
    out = i18n.t("hi", "alerts.title.SHORTAGE_PREDICTED",
                 district="GAU", level="गंभीर")
    assert "GAU" in out and "गंभीर" in out and "{" not in out


def test_t_unformatted_template_keeps_placeholder_visible():
    out = i18n.t("en", "alerts.title.SYSTEM")   # {level} uninterpolated
    assert "{level}" in out


def test_fallback_to_en_when_key_missing_in_language(monkeypatch):
    monkeypatch.delitem(CATALOGS["hi"], "nav.settings")
    assert i18n.t("hi", "only.own.key") == "only.own.key"
    assert i18n.t("hi", "nav.settings") == "Settings"   # xx -> en fallback
def test_normalize_lang_variants():
    assert i18n.normalize_lang("hi-IN") == "hi"
    assert i18n.normalize_lang("AS") == "as"
    assert i18n.normalize_lang(" as ") == "as"
    assert i18n.normalize_lang(None) == "en"
    assert i18n.normalize_lang("") == "en"
    assert i18n.normalize_lang("bn") == "en"   # planned, NOT MVP -> honest default
    assert i18n.normalize_lang("fr-CA,en") == "en"


def test_t_unsupported_language_falls_back_to_english():
    assert i18n.t("bn", "nav.dashboard") == "Dashboard"


# ------------------------------------------------------------ resolve order
class _Req:
    def __init__(self, query=None, header=None):
        self.query_params = query or {}
        self.headers = {"accept-language": header} if header else {}


class _Principal:
    def __init__(self, language):
        self.language = language


def test_resolution_query_beats_header_beats_profile():
    p = _Principal("as")
    assert i18n.resolve_lang(_Req({"lang": "hi"}, "en"), p) == "hi"
    assert i18n.resolve_lang(_Req({}, "en"), p) == "en"
    assert i18n.resolve_lang(_Req({}), p) == "as"
    assert i18n.resolve_lang(_Req({}), None) == "en"


def test_resolution_accept_language_q_values():
    assert i18n.resolve_lang(_Req({}, "as;q=0.9,hi;q=0.8")) == "as"


def test_resolution_invalid_values_never_error():
    req = _Req({"lang": "xx"}, "zz")
    assert i18n.resolve_lang(req, _Principal("!!")) == "en"

# ---------------------------------------------------- localized alerts (C15)
def _road_alert_row():
    return {
        "id": "a1", "level": "CRITICAL", "alert_type": "ROAD_WARNING",
        "title": "Road disruption in GAU (Critical)",
        "message": "Landslide validated in GAU.",
        "status": "ACTIVE", "district_code": "GAU",
        "payload": {"incident_type": "LANDSLIDE"},
    }


@pytest.mark.parametrize("lang,marker", [
    ("hi", "सड़क अवरोध"),
    ("as", "পথ অৱৰোধ"),
])
def test_localized_alert_title_and_emergency(lang, marker):
    out = i18n.localized_alert(_road_alert_row(), lang)
    assert marker in out["title_lang"]
    assert out["emergency_instruction"]           # non-empty guidance present
    assert out["level_lang"] in ("गंभीर", "গুৰুতৰ")
    assert out["status_lang"]
    # localized output must differ from canonical english
    assert out["title_lang"] != _road_alert_row()["title"]


def test_localized_alert_unknown_type_keeps_canonical_text():
    row = _road_alert_row()
    row["alert_type"] = "MYSTERY_TYPE"
    row["payload"] = {}
    out = i18n.localized_alert(row, "hi")
    assert out["title_lang"] == row["title"]      # graceful degradation
    assert (out["emergency_instruction"]
            == i18n.t("hi", "alerts.emergency.GENERIC"))


def test_alert_templates_exist_for_every_type_and_level():
    for atype in i18n.ALERT_TYPES:
        for code in ("en", "hi", "as"):
            assert f"alerts.title.{atype}" in CATALOGS[code]
            assert f"alerts.message.{atype}" in CATALOGS[code]
            assert f"alerts.type.{atype}" in CATALOGS[code]
    for level in i18n.LEVELS:
        for code in ("en", "hi", "as"):
            assert f"alerts.level.{level}" in CATALOGS[code]


def test_emergency_instructions_cover_all_field_incident_types():
    for itype in i18n.INCIDENT_TYPES:
        for code in ("en", "hi", "as"):
            assert f"alerts.emergency.{itype}" in CATALOGS[code]

# ------------------------------------------------------- field schema (C12)
def test_field_form_schema_complete_and_translated():
    schema = i18n.field_form_schema("hi")
    assert schema["language"] == "hi"
    ids = [f["id"] for f in schema["fields"]]
    assert set(ids) == {"token", "type", "severity", "photo", "description"}
    type_field = next(f for f in schema["fields"] if f["id"] == "type")
    assert [o["value"] for o in type_field["options"]] == list(i18n.INCIDENT_TYPES)
    type_label = type_field["options"][0]["label"]
    assert type_label == i18n.t("hi", "field.incident_type.LANDSLIDE")
    assert all(schema["instructions"].values())
    assert schema["submit_label"]


def test_field_schema_normalizes_region_suffix():
    assert i18n.field_form_schema("as-IN")["language"] == "as"


# ------------------------------------------- supply recommendations (C06/C07)
def test_recommendation_coverage_matches_supply_engine_outputs():
    try:
        from app.supply.service import recommended_action
    except ModuleNotFoundError:
        from supply.service import recommended_action
    produced = set()
    for prob in (10, 40, 45, 60, 65, 75, 80):
        for commodity in ("MEDICINE", "FOOD_GRAIN"):
            for incoming in (0.0, 300.0):
                produced.add(recommended_action(prob, commodity, incoming)[0])
    assert produced == set(i18n.SUPPLY_ACTIONS)
    for action in produced:
        for code in ("en", "hi", "as"):
            assert f"supply.action.{action}" in CATALOGS[code]


def test_localize_supply_prediction_adds_readonly_fields():
    pred = {"recommended_action": "PRE_POSITION", "demand_label": "HIGH"}
    out = i18n.localize_supply_prediction(pred, "as")
    out_action = out["recommended_action_lang"]
    assert out_action == i18n.t("as", "supply.action.PRE_POSITION")
    assert out["demand_label_lang"] == i18n.t("as", "supply.demand.HIGH")
    # original machine-readable codes preserved
    assert out["recommended_action"] == "PRE_POSITION"


def test_supported_languages_metadata_shape():
    for code, meta in i18n.SUPPORTED_LANGUAGES.items():
        assert meta["name"] and meta["native_name"]



