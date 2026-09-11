@echo off
REM ----------------------------------------------------------------------
REM  NER-SHIELD V2 backend — local launcher (Windows).
REM
REM  Loads .env if present, then starts uvicorn on 0.0.0.0:8000 so an
REM  Android emulator on the same host can reach the service via
REM  http://10.0.2.2:8000/api/v1.
REM ----------------------------------------------------------------------
setlocal

REM Prefer the project's own virtualenv if it exists.
if exist ".venv\Scripts\python.exe" (
  set "PYEXE=.venv\Scripts\python.exe"
) else (
  where python >nul 2>nul
  if errorlevel 1 (
    echo [ERROR] python not found on PATH and no .venv present.
    exit /b 1
  )
  set "PYEXE=python"
)

if not exist ".env" (
  echo [WARN] .env not found; falling back to .env.example placeholders.
  echo        Many endpoints will fail until real values are provided.
  if exist ".env.example" (
    copy /Y ".env.example" ".env" >nul
  )
)

REM uvicorn reads env vars automatically; .env is consumed by pydantic-settings.
%PYEXE% -m uvicorn app.main:app --host 0.0.0.0 --port 8000 %*

endlocal