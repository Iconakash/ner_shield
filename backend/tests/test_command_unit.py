"""Phase 18 unit tests — Command Center aggregation contracts (FR-C16.1).

Pure checks: frozen tile list, thresholds shared with other engines, and the
summary() response shape via a fake DB session (no infra needed).
"""
import asyncio

import pytest

try:
    from app.command import service as cmd
except ModuleNotFoundError:
    from command import service as cmd


# ------------------------------------------------------------- frozen tiles
def test_exactly_six_actionable_tiles():
    """Source mandate: actionable info only — this list is FROZEN."""
    assert list(cmd.kpi_definitions()) == [
        "critical_alerts", "high_risk_roads", "active_shipments",
        "critical_shipments", "supply_risk_districts",
        "predicted_disruptions"]


def test_every_tile_has_operator_description():
    for desc in cmd.kpi_definitions().values():
        assert isinstance(desc, str) and desc.strip()


# ---------------------------------------------------------------- thresholds
def test_supply_risk_threshold_matches_watchlist():
    """/command KPI and /supply/watchlist must tell the same story."""
    try:
        from app.supply.service import CRITICAL_COMMODITIES  # noqa: F401
    except ModuleNotFoundError:
        from supply.service import CRITICAL_COMMODITIES  # noqa: F401
    assert cmd.SUPPLY_RISK_PROBABILITY == 55.0   # watchlist SQL threshold


def test_label_vocabularies_within_prediction_domain():
    valid = ("LOW", "GUARDED", "ELEVATED", "HIGH", "CRITICAL")
    assert set(cmd.HIGH_RISK_LABELS) <= set(valid)
    assert set(cmd.PREDICTED_LABELS) <= set(valid)
    # road risk is strictly stronger than district-level flagging
    assert set(cmd.HIGH_RISK_LABELS) < set(cmd.PREDICTED_LABELS)


def test_active_shipment_statuses_are_pre_delivery():
    delivered = {"DELIVERED", "CANCELLED", "DRAFT"}
    assert not set(cmd.ACTIVE_SHIPMENT_STATUSES) & delivered
    assert set(cmd.ACTIVE_SHIPMENT_STATUSES) == {"ROUTE_ASSIGNED", "IN_TRANSIT"}


def test_open_alert_statuses_exclude_closed():
    assert set(cmd.OPEN_ALERT_STATUSES) == {"ACTIVE", "ESCALATED"}


# ------------------------------------------------------------ layer registry
def test_layer_registry_covers_the_map_toolbar():
    assert set(cmd.LAYER_BUILDERS) == {
        "high-risk-roads", "disruptions", "shipments", "weather"}


def test_all_layer_builders_are_callable_coroutines():
    import inspect
    for fn in cmd.LAYER_BUILDERS.values():
        assert inspect.iscoroutinefunction(fn)


# --------------------------------------------- summary() shape via fake session
class _Result:
    def mappings(self):
        return self

    def one(self):
        # the exact tile values from the Phase-18 specification
        return {"critical_alerts": 7, "high_risk_roads": 34,
                "active_shipments": 218, "critical_shipments": 17,
                "supply_risk_districts": 5, "predicted_disruptions": 12}


class _FakeDB:
    def __init__(self):
        self.last_params = None

    async def execute(self, _sql, params=None):
        self.last_params = params
        return _Result()


@pytest.mark.parametrize("param_key,expected", [
    ("prob", 55.0),
    ("st1", "ACTIVE"), ("st2", "ESCALATED"),
    ("shp1", "ROUTE_ASSIGNED"), ("shp2", "IN_TRANSIT"),
])
def test_summary_binds_frozen_constants_as_params(param_key, expected):
    db = _FakeDB()
    result = asyncio.run(cmd.summary(db))
    assert db.last_params[param_key] == expected
    assert result is not None


def test_summary_shape_matches_source_specification():
    """The dashboard renders EXACTLY these six counts (spec: 07/34/218/17/05/12)."""
    result = asyncio.run(cmd.summary(_FakeDB()))
    assert result["title"] == "NER-SHIELD COMMAND CENTER"
    assert result["counts"] == {
        "critical_alerts": 7, "high_risk_roads": 34,
        "active_shipments": 218, "critical_shipments": 17,
        "supply_risk_districts": 5, "predicted_disruptions": 12}
    assert [k["id"] for k in result["kpis"]] == list(cmd.kpi_definitions())
    for tile in result["kpis"]:
        assert tile["count"] == result["counts"][tile["id"]]
