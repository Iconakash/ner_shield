"""Phase 10 §10.3 — optional LLM advisory layer tests.

The advisory layer is STRICTLY advisory: it only restates deterministic decision
state and never invents risk scores, routes, or evidence. These tests verify
that safety property plus the pure-function contract (no mutation, graceful LLM
fallback)."""
import sys as _sys
from pathlib import Path
from unittest.mock import patch

import pytest

BACKEND = Path(__file__).resolve().parents[1]
if str(BACKEND) not in _sys.path:
    _sys.path.insert(0, str(BACKEND))

from app.decisions.llm_advisory import (  # noqa: E402
    _template_explain, explain_recommendation, explain_recommendations)


def _sample_rec():
    return {
        "id": "abc123",
        "rule": "REROUTE_SHIPMENT",
        "title": "Reroute shipment SH-1",
        "recommended_action": "Reroute SH-1 via NH-27 bypass",
        "reason": "HIGH disruption risk on NH-54 (78% now, 85% in 24h)",
        "confidence": 78.0,
        "affected_entities": [
            {"type": "SHIPMENT", "id": "SH-1", "label": "SH-1"},
            {"type": "ROAD_SEGMENT", "id": "SEG-9", "label": "NH-54"},
        ],
        "expected_impact": "Avoids a likely 6h closure",
        "approval_required": "EMERGENCY_REROUTE",
        "evidence": [{"type": "disruption_prediction", "id": "SEG-9"}],
    }


# ------------------------------------------------ template backend (default)
def test_template_explain_contains_action_and_reason():
    text = _template_explain(_sample_rec())
    assert "Reroute SH-1 via NH-27 bypass" in text
    assert "HIGH disruption risk" in text


def test_template_explain_exposes_confidence_and_approval():
    text = _template_explain(_sample_rec())
    assert "Confidence: 78.0%" in text
    assert "EMERGENCY_REROUTE" in text


def test_template_explain_lists_affected_entities():
    text = _template_explain(_sample_rec())
    assert "SH-1" in text
    assert "NH-54" in text


def test_template_explain_no_approval_when_none():
    rec = _sample_rec()
    rec["approval_required"] = None
    text = _template_explain(rec)
    assert "No approval required" in text


# ---------------------------------------------- safety: never invents values
def test_template_explain_does_not_invent_risk_score():
    """A recommendation with no confidence must NOT fabricate one."""
    rec = _sample_rec()
    rec["confidence"] = None
    text = _template_explain(rec)
    assert "Confidence:" not in text   # no invented number


def test_template_explain_handles_minimal_rec():
    """A nearly-empty rec must still produce text without crashing or
    inventing fields it was not given."""
    text = _template_explain({})
    assert "Decision recommendation" in text  # default title
    assert "No action specified" in text


# --------------------------------------------------- pure-function contract
def test_explain_recommendation_does_not_mutate_input():
    rec = _sample_rec()
    before = rec.copy()
    explain_recommendation(rec)
    assert rec == before


def test_explain_recommendations_returns_new_list():
    recs = [_sample_rec()]
    out = explain_recommendations(recs)
    assert out is not recs
    assert out[0] is not recs[0]            # dicts copied, not aliased
    assert "explanation" in out[0]
    assert "explanation" not in recs[0]     # original untouched


def test_explain_recommendation_rejects_non_dict():
    with pytest.raises(TypeError):
        explain_recommendation(["not", "a", "dict"])


# --------------------------------------------------- LLM backend + fallback
def test_llm_backend_used_when_configured(requests_mock=None):
    """When LLM_ENDPOINT is set, the module attempts the LLM call. We mock the
    HTTP layer by patching urlopen; on a good response the LLM text is used."""
    import urllib.request

    fake_resp = b'{"text": "LLM summary of the reroute decision."}'

    class _FakeResp:
        def read(self):
            return fake_resp

        def __enter__(self):
            return self

        def __exit__(self, *a):
            return False

    rec = _sample_rec()
    with patch.dict("os.environ", {"LLM_ENDPOINT": "http://llm.test/chat"}), \
         patch.object(urllib.request, "urlopen", return_value=_FakeResp()):
        text = explain_recommendation(rec)
    assert text == "LLM summary of the reroute decision."


def test_llm_fallback_to_template_on_error():
    """If the LLM call fails, the template is used — the endpoint never breaks.
    This is the key graceful-degrade guarantee."""
    import urllib.request

    def _boom(*a, **k):
        raise urllib.error.URLError("connection refused")

    rec = _sample_rec()
    with patch.dict("os.environ", {"LLM_ENDPOINT": "http://llm.test/chat"}), \
         patch.object(urllib.request, "urlopen", side_effect=_boom):
        text = explain_recommendation(rec)
    # Fell back to template → contains the deterministic action.
    assert "Reroute SH-1 via NH-27 bypass" in text


def test_llm_openai_shape_response():
    """Also accepts the OpenAI-style {"choices": [{"message": {"content":}}]}
    response shape."""
    import urllib.request

    fake_resp = (b'{"choices": [{"message": {"content": "OpenAI-style sum"}}]}')

    class _FakeResp:
        def read(self):
            return fake_resp

        def __enter__(self):
            return self

        def __exit__(self, *a):
            return False

    rec = _sample_rec()
    with patch.dict("os.environ", {"LLM_ENDPOINT": "http://llm.test/chat"}), \
         patch.object(urllib.request, "urlopen", return_value=_FakeResp()):
        text = explain_recommendation(rec)
    assert text == "OpenAI-style sum"