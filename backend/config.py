from pathlib import Path
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "SoundFlow Backend"
    frontend_app_url: str = "http://localhost:3000"
    cors_allow_origin: str = "*"

    # OAuth client ids/secrets
    spotify_client_id: str = ""
    spotify_client_secret: str = ""
    spotify_redirect_uri: str = "http://127.0.0.1:8000/auth/spotify/callback"
    deezer_app_id: str = ""
    deezer_secret: str = ""
    apple_developer_token: str = ""

    # Last.fm
    lastfm_api_key: str = ""  
    openrouter_api_key: str = ""          # ← agrega esta línea

    # DB
    database_url: str = "sqlite:///./soundflow.db"

    jwt_secret: str = "dev-secret-change"
    jwt_alg: str = "HS256"

    class Config:
        env_file = Path(__file__).resolve().parent / ".env"


settings = Settings()