"""Structured logging (Phase 1 stability / Phase 10 observability foundation).

JSON lines in prod (machine-parseable, request-id correlation), concise text in
dev. Call setup_logging() once at app creation. Loggers never include secrets:
tokens, keys, or credentials must not be passed as log arguments.
"""
import json
import logging
import sys

from app.core.request_context import get_request_id


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "ts": self.formatTime(record, "%Y-%m-%dT%H:%M:%S%z"),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "request_id": get_request_id(),
        }
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        # extra fields attached via logger.info(..., extra={"data": {...}})
        data = getattr(record, "data", None)
        if data:
            payload["data"] = data
        return json.dumps(payload, default=str)


def setup_logging(level: str = "INFO", *, json_mode: bool | None = None) -> None:
    if json_mode is None:
        from app.config import get_settings
        json_mode = get_settings().ENV == "prod"
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter() if json_mode
                         else logging.Formatter("%(asctime)s %(levelname)s %(name)s %(message)s"))
    root = logging.getLogger()
    root.handlers[:] = [handler]
    root.setLevel(getattr(logging, level.upper(), logging.INFO))
    # uvicorn configures its own loggers; align them with ours
    for name in ("uvicorn", "uvicorn.access", "uvicorn.error"):
        lg = logging.getLogger(name)
        lg.handlers[:] = [handler]
        lg.propagate = False


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(name)
