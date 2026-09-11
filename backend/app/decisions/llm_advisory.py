# -*- coding: utf-8 -*-
"""Optional LLM advisory interpretation layer (Phase 10 §10.3).

STRICTLY ADVISORY. Per master prompt §10.3 this module NEVER:

  * invents risk scores, routes, or evidence
  * overrides deterministic decisions or safety rules
  * modifies database state
  * approves dangerous operational decisions

It produces natural-language explanations of DETERMINISTIC decision state that
already exists. The recommendation contract is complete WITHOUT this layer —
every card carries reason, confidence, affected entities, expected impact,
recommended action and approval requirement on its own. This is a pure
read-only interpretation aid layered on top.

Architecture (master prompt §10.3):

    Deterministic engines → evidence → decision state → optional explanation

Two explanation backends, selected by configuration:

  * template (default) — deterministic natural-language restatement. No
    external dependency, no latency, no fabrication. Always available.
  * llm (optional) — if LLM_ENDPOINT is configured, the same structured prompt
    is sent to the model and its text returned. The prompt contains ONLY facts
    the deterministic engine already produced; the model is asked to summarise,
    not to decide. If the LLM call fails, we fall back to the template so the
    endpoint never breaks.

The function only READS the recommendation dict. It cannot invent values because
it has no access to raw data sources — only the already-computed decision state.
"""
import json
import logging
import os
import urllib.error
import urllib.request

logger = logging.getLogger("ner-shield.decisions.llm_advisory")

_FROM_FIELDS = ("recommended_action", "reason", "confidence",
                "affected_entities", "expected_impact", "approval_required")


def _template_explain(rec: dict) -> str:
    """Deterministic natural-language explanation — no LLM needed. Restates ONLY
    what the deterministic engine already decided. Fixed format → predictable,
    never fabricates a value the engine did not produce."""
    title = rec.get("title", "Decision recommendation")
    action = rec.get("recommended_action", "No action specified")
    reason = rec.get("reason", "")
    confidence = rec.get("confidence")
    impact = rec.get("expected_impact", "")
    approval = rec.get("approval_required")

    affected = rec.get("affected_entities") or []
    affected_str = ", ".join(
        f"{a.get('label', a.get('id', '?'))}" for a in affected[:3])
    if len(affected) > 3:
        affected_str += f" (+{len(affected) - 3} more)"

    parts = [f"{title}.", f"Recommended action: {action}."]
    if reason:
        parts.append(f"Rationale: {reason}.")
    if affected_str:
        parts.append(f"Affected: {affected_str}.")
    if confidence is not None:
        parts.append(f"Confidence: {confidence}%.")
    if impact:
        parts.append(f"Expected impact: {impact}.")
    if approval:
        parts.append(f"Requires approval: {approval}.")
    else:
        parts.append("No approval required.")
    return " ".join(parts)


def _llm_explain(rec: dict, evidence, endpoint: str, timeout_s: float) -> str:
    """Call an external LLM to summarise the deterministic decision. The prompt
    contains ONLY facts already produced by the engine; we ask for a short
    operational summary, NOT a decision. Returns the template on any failure so
    the advisory layer degrades gracefully."""
    prompt = (
        "You are a logistics decision-support assistant. Summarise the following"
        " deterministic recommendation in 2-3 short sentences for a district"
        " officer. Do NOT invent any risk score, route, or evidence. Do NOT"
        " override the recommended action. Only restate the facts given.\n\n"
        f"Recommendation:\n{json.dumps(rec, default=str)}\n\n"
        f"Evidence:\n{json.dumps(evidence or [], default=str)}\n\n"
        "Summary:"
    )
    body = json.dumps({"prompt": prompt, "max_tokens": 200}).encode()
    req = urllib.request.Request(
        endpoint, data=body, headers={"Content-Type": "application/json"},
        method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout_s) as resp:
            payload = json.loads(resp.read().decode())
        # Accept either {"text": ...} or OpenAI-style {"choices": [...]}
        text = (payload.get("text")
                or (payload.get("choices", [{}])[0].get("message", {}).get(
                    "content")))
        if isinstance(text, str) and text.strip():
            return text.strip()
        logger.warning("llm_advisory: empty/unexpected response shape")
    except (urllib.error.URLError, urllib.error.HTTPError, OSError,
            json.JSONDecodeError, KeyError) as exc:
        logger.warning("llm_advisory: LLM call failed, using template: %s", exc)
    return _template_explain(rec)


def explain_recommendation(rec: dict, evidence=None) -> str:
    """Explain one deterministic recommendation in natural language. Pure
    function: reads `rec`, never mutates it, never touches the database. If
    LLM_ENDPOINT is configured, uses the LLM backend (with template fallback);
    otherwise uses the deterministic template. Either way the recommendation is
    unaffected — this only produces an explanation string."""
    if not isinstance(rec, dict):
        raise TypeError("recommendation must be a dict")
    endpoint = os.environ.get("LLM_ENDPOINT")
    if endpoint:
        return _llm_explain(rec, evidence, endpoint,
                             float(os.environ.get("LLM_TIMEOUT_S", "8")))
    return _template_explain(rec)


def explain_recommendations(recs: list[dict]) -> list[dict]:
    """Return a NEW list with an added `explanation` field on each
    recommendation. Pure: the input list and its dicts are not mutated."""
    out = []
    for rec in recs:
        card = dict(rec)
        card["explanation"] = explain_recommendation(rec)
        out.append(card)
    return out