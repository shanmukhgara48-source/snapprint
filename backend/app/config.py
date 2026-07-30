from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    env: str = "development"
    database_url: str = "postgresql+asyncpg://postgres:password@localhost:5432/snapprint"
    secret_key: str = ""  # MUST be set via env — app raises on startup if empty
    frontend_url: str = "http://localhost:3000"
    allowed_origins: str = "http://localhost:3000"
    allowed_hosts: str = "*"

    firebase_credentials_path: str = "./snap-print-7146d-firebase-adminsdk-fbsvc-fa3893d412.json"
    firebase_credentials_json: str = ""
    firebase_storage_bucket: str = ""
    firebase_project_id: str = ""
    firebase_api_key: str = ""
    razorpay_key_id: str = ""
    razorpay_key_secret: str = ""

    # Cloudflare R2
    r2_account_id: str = ""
    r2_access_key_id: str = ""
    r2_secret_access_key: str = ""
    r2_bucket_name: str = "snap-photo"
    r2_public_url: str = ""

    # Google Gemini / GenAI. Keep keys server-side only; never ship them to Flutter.
    gemini_api_key: str = ""
    google_api_key: str = ""
    gemini_image_model: str = "gemini-3.1-flash-image"
    gemini_text_model: str = "gemini-3.5-flash"

    # Admin credentials
    admin_username: str = "admin"
    admin_password: str = "changeme123"

    # JWT
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7 days

    # Dev-only bypass (empty = disabled; set in .env for local QA only)
    dev_bypass_secret: str = ""

    @field_validator("database_url")
    @classmethod
    def normalize_database_url(cls, value: str) -> str:
        # Hosts like Railway often provide postgres:// or postgresql:// URLs.
        # The async SQLAlchemy engine needs the asyncpg dialect explicitly.
        if value.startswith("postgres://"):
            return value.replace("postgres://", "postgresql+asyncpg://", 1)
        if value.startswith("postgresql://"):
            return value.replace("postgresql://", "postgresql+asyncpg://", 1)
        return value

    @property
    def is_production(self) -> bool:
        return self.env.lower() == "production"

    @property
    def allowed_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.allowed_origins.split(",") if origin.strip()]

    @property
    def allowed_host_list(self) -> list[str]:
        return [host.strip() for host in self.allowed_hosts.split(",") if host.strip()]


settings = Settings()
