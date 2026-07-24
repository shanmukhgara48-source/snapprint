from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://postgres:password@localhost:5432/snapprint"

    @field_validator("database_url")
    @classmethod
    def _use_asyncpg_driver(cls, v: str) -> str:
        # Railway (and most managed Postgres providers) hand out postgres:// or
        # postgresql:// — SQLAlchemy's async engine needs the +asyncpg driver suffix.
        if v.startswith("postgres://"):
            return v.replace("postgres://", "postgresql+asyncpg://", 1)
        if v.startswith("postgresql://"):
            return v.replace("postgresql://", "postgresql+asyncpg://", 1)
        return v
    secret_key: str = ""  # MUST be set via env — app raises on startup if empty
    firebase_credentials_path: str = "./snap-print-7146d-firebase-adminsdk-fbsvc-fa3893d412.json"
    # Set on Railway/cloud hosts where the JSON file can't be committed: paste the
    # full service-account JSON contents in as this env var instead of a file path.
    firebase_credentials_json: str = ""
    firebase_storage_bucket: str = ""
    razorpay_key_id: str = ""
    razorpay_key_secret: str = ""

    # Cloudflare R2
    r2_account_id: str = ""
    r2_access_key_id: str = ""
    r2_secret_access_key: str = ""
    r2_bucket_name: str = "snap-photo"
    r2_public_url: str = ""

    # Admin credentials
    admin_username: str = "admin"
    admin_password: str = "changeme123"

    # JWT
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7 days

    # Dev-only bypass (empty = disabled; set in .env for local QA only)
    dev_bypass_secret: str = ""


settings = Settings()
