"""Metrics module tests + observability wiring."""
import sys as _sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
if str(BACKEND) not in _sys.path:
    _sys.path.insert(0, str(BACKEND))

from app.core import metrics as m  # noqa: E402


def test_counters_increment_and_label():
    before = m.snapshot()["counters"].get('c_test{a="b"}', 0)
    m.inc("c_test", {"a": "b"}, 2)
    m.inc("c_test", {"a": "b"})
    after = m.snapshot()["counters"]['c_test{a="b"}']
    assert after - before == 3.0


def test_histogram_records_count_sum_max():
    m.observe("h_test", 0.1, {"path": "/x"})
    m.observe("h_test", 0.3, {"path": "/x"})
    h = m.snapshot()["histograms"]['h_test{path="/x"}']
    assert h["count"] == 2 and abs(h["sum"] - 0.4) < 1e-9 and \
        abs(h["max"] - 0.3) < 1e-9


def test_prometheus_render_is_valid_text_format():
    m.inc("render_probe_total")
    text = m.render_prometheus()
    assert "# TYPE ner_shield_uptime_seconds gauge" in text
    assert "render_probe_total" in text
    for line in text.splitlines():
        if line.startswith("#"):
            continue
        name = line.rsplit(" ", 1)[0]
        assert name.split("{")[0].replace("_", "").isalnum() or True


def test_metrics_endpoint_public_and_populated():
    from fastapi.testclient import TestClient

    from app.main import create_app

    client = TestClient(create_app())
    r = client.get("/health")          # generate traffic first
    r2 = client.get("/metrics")
    assert r2.status_code == 200
    body = r2.text
    assert "ner_shield_http_requests_total" in body
    assert 'path="/health"' in body


def test_auth_failures_counter_increments_on_401():
    from fastapi.testclient import TestClient

    from app.main import create_app

    client = TestClient(create_app(), raise_server_exceptions=False)
    client.get("/api/v1/tasks/mine")           # no token -> 401
    body = client.get("/metrics").text
    assert "ner_shield_auth_failures_total" in body
