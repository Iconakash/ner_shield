"""GPS device telemetry module (master upgrade §10).

Devices authenticate with their own credentials (X-Device-Code /
X-Device-Secret) — never with user JWTs. The ingest endpoint is deliberately
self-authenticated and therefore excluded from the bearer gate.
"""
