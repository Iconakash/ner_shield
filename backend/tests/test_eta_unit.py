"""Phase 11 unit tests — predictive ETA math (pure helpers)."""
import pytest

from app.shipments.service import (
    RISK_DELAY_SENSITIVITY, fmt_duration, segment_delay_minutes)


def test_segment_delay_zero_risk_is_free():
    assert segment_delay_minutes(100, 40, risk_pct=0) == 0.0


def test_segment_delay_scales_with_risk_and_length():
    # 100 km at 40 kph = 2.5 h; full risk => 2.5 * sensitivity hours in minutes
    expected = 150.0 * (RISK_DELAY_SENSITIVITY / 1.5)
    d = segment_delay_minutes(100, 40, 100)
    assert d == pytest.approx(2.5 * RISK_DELAY_SENSITIVITY * 60)
    half = segment_delay_minutes(100, 40, 50)
    assert half == pytest.approx(d / 2)


def test_example_shape_normal_plus_disruption():
    """4h40 normal + 2h10 disruption = 6h50 (source example)."""
    normal = 280
    disruption = 130
    total = normal + disruption
    assert fmt_duration(normal) == "4h40"
    assert fmt_duration(disruption) == "2h10"
    assert fmt_duration(total) == "6h50"


def test_fmt_duration_rounds():
    assert fmt_duration(59.4) == "0h59"
    assert fmt_duration(60) == "1h00"
    assert fmt_duration(125) == "2h05"
