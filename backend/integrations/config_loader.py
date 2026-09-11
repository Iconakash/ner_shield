"""Deployment-time provider configuration loader (feature-flag wiring).

Reads the *_ENABLED / *_BASE_URL environment variables and flips the matching
adapter slots via each service's reconfigure(). Code defaults stay DISABLED;
this loader runs once at worker startup so a missing/blank env keeps every
provider off — the application always boots without any external API.
Secrets are NEVER read here; credentials are resolved lazily at fetch time from
the env names declared by each adapter (api_key_env / CLIENT_ID_ENV etc.).
"""
import logging
import os

from integrations.disaster import sachet_service
from integrations.disaster.sachet import DEFAULT_CONFIG as SACHET_CFG
from integrations.hydrology import service as hydrology_svc
from integrations.hydrology.adapter import DEFAULT_CONFIG as CWC_CFG
from integrations.routing import service as routing_svc
from integrations.routing.providers import DEFAULT_CONFIG as OSRM_CFG
from integrations.satellite import copernicus_service
from integrations.satellite.copernicus import (
    DEFAULT_CONFIG as COPERNICUS_CFG, DEFAULT_TOKEN_URL)
from integrations.weather import imd_service
from integrations.weather import service as weather_svc
from integrations.weather.adapter import DEFAULT_CONFIG as WEATHER_CFG
from integrations.weather.imd import DEFAULT_CONFIG as IMD_CFG

logger = logging.getLogger("ner-shield.integrations.config")


def _flag(name: str) -> bool:
    return os.environ.get(name, "").strip().lower() in ("1", "true", "yes", "on")


def apply() -> int:
    """Configure all optional providers from env. Returns count enabled."""
    enabled = 0

    if _flag("IMD_ENABLED") and os.environ.get("IMD_BASE_URL"):
        imd_service.reconfigure(IMD_CFG.model_copy(update={
            "enabled": True, "endpoint": os.environ["IMD_BASE_URL"]}))
        enabled += 1

    if _flag("WEATHER_ENABLED") and os.environ.get("WEATHER_BASE_URL"):
        weather_svc.reconfigure(WEATHER_CFG.model_copy(update={
            "enabled": True, "endpoint": os.environ["WEATHER_BASE_URL"]}))
        enabled += 1

    if _flag("SACHET_ENABLED") and os.environ.get("SACHET_BASE_URL"):
        sachet_service.reconfigure(SACHET_CFG.model_copy(update={
            "enabled": True, "endpoint": os.environ["SACHET_BASE_URL"]}))
        enabled += 1

    if _flag("COPERNICUS_ENABLED") and os.environ.get("COPERNICUS_BASE_URL"):
        token_url = os.environ.get("COPERNICUS_TOKEN_URL") or DEFAULT_TOKEN_URL
        copernicus_service.reconfigure(COPERNICUS_CFG.model_copy(update={
            "enabled": True,
            "endpoint": os.environ["COPERNICUS_BASE_URL"]}))
        copernicus_service.get_adapter()._token_url = token_url
        enabled += 1

    if _flag("CWC_ENABLED") and os.environ.get("CWC_BASE_URL"):
        hydrology_svc.reconfigure(CWC_CFG.model_copy(update={
            "enabled": True, "endpoint": os.environ["CWC_BASE_URL"]}))
        enabled += 1

    if (_flag("ROUTING_ENABLED") and _flag("OSRM_ENABLED")
            and os.environ.get("ROUTING_PROVIDER", "").lower() == "osrm"
            and os.environ.get("OSRM_BASE_URL")):
        routing_svc.reconfigure(OSRM_CFG.model_copy(update={
            "enabled": True, "endpoint": os.environ["OSRM_BASE_URL"]}))
        enabled += 1
    else:
        routing_svc.reconfigure(None)   # internal graph engine stays default

    logger.info("provider configuration applied",
                extra={"data": {"enabled_providers": enabled}})
    return enabled