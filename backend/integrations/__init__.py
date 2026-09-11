"""NER-SHIELD external-data integration layer.

Every external source lives behind an adapter with: interface, authentication,
timeout, retry, rate limiting, schema validation, logging, error handling,
health status, last-success tracking, and source confidence. Sources that are
not yet authorized/configured report UNAVAILABLE — simulated data is never
substituted for live data (master upgrade Rule 2).
"""
