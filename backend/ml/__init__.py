"""ML training + inference support package.

Imported as ``ml.*`` when the backend directory is the working/root context, or
``backend.ml.*`` when the repository root is. Importers use a small try/except
shim (see app/risk/service.py) so both deployment layouts work.
"""

