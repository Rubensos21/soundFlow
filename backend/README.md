SoundFlow Backend (FastAPI)

Desarrollo rápido:

1) Crear entorno y dependencias

```
python -m venv .venv
. .venv/Scripts/activate  # Windows PowerShell: .venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

2) Variables de entorno (.env)

```
DATABASE_URL=sqlite:///./soundflow.db
SPOTIFY_CLIENT_ID=...
SPOTIFY_CLIENT_SECRET=...
DEEZER_APP_ID=...
DEEZER_SECRET=...
APPLE_DEVELOPER_TOKEN=...
```

3) Ejecutar

```
uvicorn backend.app:app --reload --port 8000
```

Endpoints clave:
- GET /health
- GET /auth/{platform}
- GET /auth/{platform}/callback
- GET /me/linked-accounts
- POST /api/generate-playlist/prompt {prompt}
- POST /api/generate-playlist/facial (multipart image)

Nota: las integraciones OAuth y la IA están mockeadas para desarrollo. Sustituye por canje real de tokens y modelos.