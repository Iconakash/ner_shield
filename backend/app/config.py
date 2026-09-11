"""Application settings (architecture §13). Fails fast on missing required secrets."""
from functools import lru_cache
from typing import List, Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    ENV: Literal["dev", "test", "prod"] = "dev"

    # Supabase (AX-2/AX-3: anon key is public; service role NEVER leaves server)
    SUPABASE_URL: str
    SUPABASE_ANON_KEY: str
    SUPABASE_JWT_SECRET: str | None = None          # HS256 mode
    SUPABASE_JWKS_URL: str | None = None            # preferred RS256 mode
    SUPABASE_SERVICE_ROLE_KEY: str | None = None    # required in prod at boot

    # SIH26002 P1 — private field-photo bucket (server-side access only).
    SUPABASE_STORAGE_BUCKET: str = "field-reports"

    DATABASE_URL: str                               # user-facing pool (RLS enforced)
    SYSTEM_DATABASE_URL: str | None = None          # system jobs/audited admin paths

    API_PUBLIC_URL: str = "http://localhost:8000"
    CORS_ORIGINS: List[str] = ["http://localhost:5500", "http://127.0.0.1:5500"]

    OSM_TILE_URL: str = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
    OSM_USER_AGENT: str = "NER-SHIELD/0.1"

    # ---- external data providers (master integration upgrade) ----------------
    # Every provider is INDEPENDENTLY switchable and ships OFF. The app must
    # boot and fully function with all of these unset/false (fallback = cached
    # + demo/mock + remaining providers). Credentials are NOT stored here:
    # adapters resolve them lazily from dedicated env names at fetch time.
    IMD_ENABLED: bool = False
    IMD_BASE_URL: str | None = None            # authorized gateway endpoint
    SACHET_ENABLED: bool = False
    SACHET_BASE_URL: str | None = None         # authorized machine-readable feed
    COPERNICUS_ENABLED: bool = False
    COPERNICUS_BASE_URL: str | None = None     # OData catalogue base URL
    COPERNICUS_TOKEN_URL: str | None = None    # default documented CDSE realm
    CWC_ENABLED: bool = False
    CWC_BASE_URL: str | None = None            # authorized data-sharing endpoint
    ROUTING_ENABLED: bool = True               # internal graph engine default
    ROUTING_PROVIDER: Literal["internal", "osrm"] = "internal"
    OSRM_BASE_URL: str | None = None           # self-hosted/authorized instance

    # Login abuse controls (SEC / baseline login rules)
    LOGIN_MAX_FAILURES: int = 5
    LOGIN_LOCKOUT_WINDOW_MINUTES: int = 15
    RATE_LIMIT_PER_MINUTE: int = 120
    # (ACCESS_TOKEN_MIN_IAT_SKEW removed — P0 fix: revocation now uses
    #  profiles.token_revoked_at compared against JWT iat, never iat-vs-version.)

    # Phase 26 hardening knobs
    MAX_BODY_BYTES: int = 1_048_576            # 1 MiB JSON/API cap
    MAX_UPLOAD_BYTES: int = 10_485_760         # 10 MiB field-photo cap

    LOG_LEVEL: str = "INFO"
    DEBUG: bool = False

    # Demo/live data mode (master upgrade §70). UI must display DEMO visibly.
    DATA_MODE: Literal["demo", "live"] = "demo"

    @property
    def require_strong_config(self) -> bool:
        return self.ENV == "prod"


@lru_cache
def get_settings() -> Settings:
    s = Settings()
    if s.require_strong_config and not s.SUPABASE_SERVICE_ROLE_KEY:
        raise RuntimeError("prod boot requires SUPABASE_SERVICE_ROLE_KEY")
    if s.DEBUG and s.ENV == "prod":
        raise RuntimeError("DEBUG must be false in prod")
    if not s.SUPABASE_JWKS_URL and not s.SUPABASE_JWT_SECRET:
        raise RuntimeError("need SUPABASE_JWKS_URL or SUPABASE_JWT_SECRET for token verification")
    if s.ENV == "prod" and not s.SUPABASE_JWKS_URL:
        raise RuntimeError(
            "prod boot requires asymmetric token verification (SUPABASE_JWKS_URL); "
            "shared-secret HS256 is a development convenience only")
    if s.ENV == "prod" and s.DATA_MODE != "live":
        raise RuntimeError("prod boot requires DATA_MODE=live")
    return s

