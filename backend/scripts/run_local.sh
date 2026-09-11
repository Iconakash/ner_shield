#!/usr/bin/env bash
# ----------------------------------------------------------------------
#  NER-SHIELD V2 backend — local launcher (macOS / Linux).
#
#  Loads .env if present, then starts uvicorn on 0.0.0.0:8000 so an
#  Android emulator on the same host can reach the service via
#  http://10.0.2.2:8000/api/v1.
# ----------------------------------------------------------------------
set -euo pipefail

if [ -x ".venv/bin/python" ]; then
  PYEXE=".venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
  PYEXE="python3"
elif command -v python >/dev/null 2>&1; then
  PYEXE="python"
else
  echo "[ERROR] python not found on PATH and no .venv present." >&2
  exit 1
fi

if [ ! -f ".env" ]; then
  echo "[WARN] .env not found; falling back to .env.example placeholders."
  echo "       Many endpoints will fail until real values are provided."
  if [ -f ".env.example" ]; then
    cp -n ".env.example" ".env" || true
  fi
fi

exec "$PYEXE" -m uvicorn app.main:app --host 0.0.0.0 --port 8000 "$@"