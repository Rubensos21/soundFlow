from pathlib import Path
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "SoundFlow Backend"
    frontend_app_url: str = "http://localhost:3000"
    cors_allow_origin: str = "*"

    # OAuth client ids/secrets (usa .env reales en despliegue)
    spotify_client_id: str = "06fd242241014f3b9ec4873d6f1c010a"
    spotify_client_secret: str = "b5bba7685def489bae377c4780f339c5"
    spotify_redirect_uri: str = "http://127.0.0.1:8000/auth/spotify/callback"
    deezer_app_id: str = ""
    deezer_secret: str = ""
    apple_developer_token: str = ""

    # DB
    database_url: str = "sqlite:///./soundflow.db"

    jwt_secret: str = "dev-secret-change"
    jwt_alg: str = "HS256"

    class Config:
         env_file = Path(__file__).resolve().parent / ".env"


settings = Settings()