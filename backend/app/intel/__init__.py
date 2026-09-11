"""NER-SHIELD decision-intelligence layer.

Additive extension of the existing risk/prediction/decision stack:
  data_quality       — validation + freshness + quality metadata (never zero-fills)
  source_confidence  — DATA confidence (separate from risk / prediction confidence)
  evidence           — normalized evidence + hazard fusion + SOURCE-CONFLICT detection
  decision_state     — operational posture states + option comparison
  service            — DB assembly of assessments, cards and closed-loop outcomes

Every module here is pure logic or read-only assembly; writes still flow through
the existing audited paths (approvals, alerts, audit log).
"""
