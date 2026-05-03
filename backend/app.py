from urllib.parse import quote
from fastapi import FastAPI, Depends, Request, UploadFile, File, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse, HTMLResponse
from sqlalchemy.orm import Session
from loguru import logger
import httpx
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

from .config import settings
from .db import Base, engine, get_db
from .models import User, UserStreamingAccount, AIGeneratedPlaylist
from .ai import EmotionDetector, PromptProcessor, HybridRecommender, MoodRecommender, EMOTION_ALIAS, MOOD_PLAYLIST_NAMES


app = FastAPI(title=settings.app_name)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[settings.cors_allow_origin, "*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)

emotion_detector = EmotionDetector()
prompt_processor = PromptProcessor()


PLATFORMS = {"spotify"}

PLATFORM_NAMES = {
    "spotify": "Spotify",
    "deezer": "Deezer",
    "apple": "Apple Music",
}

MOCK_STREAMING_DATA: Dict[str, Dict[str, object]] = {
    "deezer": {
        "profile": {
            "id": "soundflow_deezer_user",
            "display_name": "Deezer Explorer",
            "email": "deezer@soundflow.app",
            "images": [
                {
                    "url": "https://images.unsplash.com/photo-1525182008055-f88b95ff7980?auto=format&fit=crop&w=300&q=80"
                }
            ],
            "followers": {"total": 824},
            "product": "premium",
            "country": "FR",
        },
        "playlists": [
            {
                "id": "deezer_morning_vibes",
                "name": "Morning Vibes",
                "description": "Comienza tu día con energía positiva",
                "tracks": {"total": 32},
                "images": [
                    {
                        "url": "https://images.unsplash.com/photo-1444824775686-4185f172c44b?auto=format&fit=crop&w=400&q=80"
                    }
                ],
                "owner": {"display_name": "Deezer"},
            },
            {
                "id": "deezer_latino_hits",
                "name": "Latino Hits",
                "description": "Lo mejor de la música latina actual",
                "tracks": {"total": 45},
                "images": [
                    {
                        "url": "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=400&q=80"
                    }
                ],
                "owner": {"display_name": "Deezer"},
            },
        ],
        "top_tracks": [
            {
                "id": "dz_track_1",
                "name": "Sunrise Colors",
                "duration_ms": 208000,
                "artists": [{"name": "Clémence"}],
                "album": {
                    "name": "Le Matin",
                    "images": [
                        {
                            "url": "https://images.unsplash.com/photo-1521335629791-ce4aec67dd47?auto=format&fit=crop&w=300&q=80"
                        }
                    ],
                },
            },
            {
                "id": "dz_track_2",
                "name": "City Lights",
                "duration_ms": 194000,
                "artists": [{"name": "Electra"}],
                "album": {
                    "name": "Neon Nights",
                    "images": [
                        {
                            "url": "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=300&q=80"
                        }
                    ],
                },
            },
        ],
        "recently_played": [
            {
                "played_at": datetime.utcnow().isoformat(),
                "track": {
                    "id": "dz_recent_1",
                    "name": "Acoustic Bloom",
                    "artists": [{"name": "Léa"}],
                    "album": {
                        "name": "Acoustic Sessions",
                        "images": [
                            {
                                "url": "https://images.unsplash.com/photo-1485579149621-3123dd979885?auto=format&fit=crop&w=300&q=80"
                            }
                        ],
                    },
                },
            },
            {
                "played_at": (datetime.utcnow() - timedelta(hours=2)).isoformat(),
                "track": {
                    "id": "dz_recent_2",
                    "name": "Electro Pulse",
                    "artists": [{"name": "Nova"}],
                    "album": {
                        "name": "Electric Dreams",
                        "images": [
                            {
                                "url": "https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=300&q=80"
                            }
                        ],
                    },
                },
            },
        ],
    },
    "apple": {
        "profile": {
            "id": "soundflow_apple_user",
            "display_name": "Apple Music Lover",
            "email": "apple@soundflow.app",
            "images": [
                {
                    "url": "https://images.unsplash.com/photo-1487215078519-e21cc028cb29?auto=format&fit=crop&w=300&q=80"
                }
            ],
            "followers": {"total": 412},
            "product": "individual",
            "country": "US",
        },
        "playlists": [
            {
                "id": "apple_chill_wave",
                "name": "Chill Wave Essentials",
                "description": "Beats suaves para relajarte",
                "tracks": {"total": 28},
                "images": [
                    {
                        "url": "https://images.unsplash.com/photo-1506157786151-b8491531f063?auto=format&fit=crop&w=400&q=80"
                    }
                ],
                "owner": {"display_name": "Apple Music"},
            },
            {
                "id": "apple_focus_flow",
                "name": "Focus Flow",
                "description": "Música instrumental para concentrarte",
                "tracks": {"total": 36},
                "images": [
                    {
                        "url": "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=400&q=80"
                    }
                ],
                "owner": {"display_name": "Apple Music"},
            },
        ],
        "top_tracks": [
            {
                "id": "apple_track_1",
                "name": "Golden Hour",
                "duration_ms": 221000,
                "artists": [{"name": "Aurora Sky"}],
                "album": {
                    "name": "Moments",
                    "images": [
                        {
                            "url": "https://images.unsplash.com/photo-1471478331149-c72f17e33c73?auto=format&fit=crop&w=300&q=80"
                        }
                    ],
                },
            },
            {
                "id": "apple_track_2",
                "name": "Midnight Cruise",
                "duration_ms": 205000,
                "artists": [{"name": "Neon Coast"}],
                "album": {
                    "name": "Skyline",
                    "images": [
                        {
                            "url": "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=300&q=80"
                        }
                    ],
                },
            },
        ],
        "recently_played": [
            {
                "played_at": datetime.utcnow().isoformat(),
                "track": {
                    "id": "apple_recent_1",
                    "name": "Ambient Fields",
                    "artists": [{"name": "Echoes"}],
                    "album": {
                        "name": "Horizons",
                        "images": [
                            {
                                "url": "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?auto=format&fit=crop&w=300&q=80"
                            }
                        ],
                    },
                },
            },
            {
                "played_at": (datetime.utcnow() - timedelta(hours=1, minutes=30)).isoformat(),
                "track": {
                    "id": "apple_recent_2",
                    "name": "Lo-Fi Roads",
                    "artists": [{"name": "Night Drive"}],
                    "album": {
                        "name": "Nightfall",
                        "images": [
                            {
                                "url": "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=300&q=80"
                            }
                        ],
                    },
                },
            },
        ],
    },
}


def get_current_user(x_device_id: str = Header(None), db: Session = Depends(get_db)) -> User:
    if not x_device_id:
        device_id = "demo_device"
    else:
        device_id = x_device_id
        
    email = f"{device_id}@soundflow.app"
    user = db.query(User).filter_by(email=email).first()
    if not user:
        user = User(email=email, display_name="App User")
        db.add(user)
        db.commit()
        db.refresh(user)
    return user


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/config/check")
def check_config():
    """Endpoint para verificar configuración (solo desarrollo)"""
    return {
        "spotify_configured": bool(settings.spotify_client_id),
        "spotify_client_id_length": len(settings.spotify_client_id) if settings.spotify_client_id else 0,
        "redirect_uri": "http://127.0.0.1:8000/auth/spotify/callback",
        "mode": "REAL" if settings.spotify_client_id else "MOCK"
    }


@app.get("/me/linked-accounts")
async def linked_accounts(db: Session = Depends(get_db)):
    user = get_current_user(None, db)
    accounts = db.query(UserStreamingAccount).filter_by(user_id=user.id).all()
    result = []

    for account in accounts:
        display_name = account.platform_user_id or "linked"
        verified = True

        if account.platform == "spotify":
            profile = await _spotify_user_profile(account.access_token, strict=False)
            if profile:
                display_name = profile.get("display_name") or profile.get("id") or display_name
                verified = True
            else:
                verified = False
        elif account.platform in {"deezer", "apple"}:
            profile = _mock_user_profile(account.platform)
            if profile:
                display_name = profile.get("display_name") or profile.get("id") or display_name
                verified = True

        result.append(
            {
                "platform": account.platform,
                "linked": True,
                "displayName": display_name,
                "verified": verified,
            }
        )

    return {"accounts": result}


def _ensure_platform_linked(db: Session, platform: str) -> UserStreamingAccount:
    user = get_current_user(None, db)
    account = (
        db.query(UserStreamingAccount)
        .filter_by(user_id=user.id, platform=platform)
        .first()
    )
    if not account:
        raise HTTPException(status_code=401, detail=f"{PLATFORM_NAMES.get(platform, platform)} no conectado")
    return account


def _get_mock_streaming_response(platform: str, key: str):
    platform_data = MOCK_STREAMING_DATA.get(platform)
    if not platform_data or key not in platform_data:
        raise HTTPException(status_code=404, detail=f"Mock de {platform} no disponible")
    data = platform_data[key]
    if isinstance(data, list):
        return {"items": data}
    return data


def _mock_user_profile(platform: str) -> Optional[Dict[str, Any]]:
    platform_data = MOCK_STREAMING_DATA.get(platform)
    if not platform_data:
        return None
    profile = platform_data.get("profile")
    if isinstance(profile, dict):
        return profile
    return None


async def _spotify_user_profile(access_token: str, strict: bool = True) -> Optional[Dict[str, Any]]:
    if not access_token:
        if strict:
            raise HTTPException(status_code=401, detail="Token de Spotify no disponible")
        return None

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                "https://api.spotify.com/v1/me",
                headers={"Authorization": f"Bearer {access_token}"},
            )

        if response.status_code != 200:
            logger.warning(
                "No se pudo verificar la cuenta de Spotify. Status=%s, Body=%s",
                response.status_code,
                response.text,
            )
            if strict:
                raise HTTPException(
                    status_code=401,
                    detail="No se pudo verificar la cuenta de Spotify con la API oficial.",
                )
            return None

        return response.json()
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error verificando perfil de Spotify: {exc}")
        if strict:
            raise HTTPException(
                status_code=500,
                detail="Error verificando la cuenta de Spotify.",
            )
        return None


@app.get("/auth/{platform}")
def auth_redirect(platform: str, device_id: str = None):
    if platform not in PLATFORMS:
        raise HTTPException(status_code=400, detail="unsupported platform")
    
    # OAuth REAL para Spotify
    if platform == "spotify":
        if not settings.spotify_client_id or not settings.spotify_client_secret:
            raise HTTPException(
                status_code=500,
                detail="Spotify OAuth no está configurado. Define SPOTIFY_CLIENT_ID y SPOTIFY_CLIENT_SECRET en .env.",
            )

        redirect_uri = settings.spotify_redirect_uri
        scope = "user-read-private user-read-email playlist-read-private playlist-read-collaborative user-top-read user-read-recently-played user-library-read"
        
        auth_url = (
            f"https://accounts.spotify.com/authorize?"
            f"client_id={settings.spotify_client_id}"
            f"&response_type=code"
            f"&redirect_uri={quote(redirect_uri, safe='')}"
            f"&scope={scope}"
            f"&show_dialog=true"
        )
        if device_id:
            auth_url += f"&state={device_id}"
        
        return RedirectResponse(url=auth_url)
    
    # Para otras plataformas, usar mock por ahora
    return RedirectResponse(url=f"/auth/{platform}/callback?code=mock_code&state=mock_state")


@app.get("/auth/{platform}/callback")
async def auth_callback(platform: str, code: str = None, state: str = None, error: str = None, db: Session = Depends(get_db)):
    if platform not in PLATFORMS:
        raise HTTPException(status_code=400, detail="unsupported platform")
    
    if error:
        logger.error(f"Error en OAuth {platform}: {error}")
        return HTMLResponse(content=f"<h1>Error: {error}</h1>")

    user = get_current_user(None, db)

    # OAuth REAL para Spotify
    if platform == "spotify":
        if not settings.spotify_client_id or not settings.spotify_client_secret:
            raise HTTPException(
                status_code=500,
                detail="Spotify OAuth no está configurado correctamente en .env.",
            )
        if not code or code == "mock_code":
            raise HTTPException(status_code=400, detail="Código de autorización inválido para Spotify.")

        try:
            # Canjear código por tokens
            token_url = "https://accounts.spotify.com/api/token"
            redirect_uri = settings.spotify_redirect_uri
            
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    token_url,
                    data={
                        "grant_type": "authorization_code",
                        "code": code,
                        "redirect_uri": redirect_uri,
                        "client_id": settings.spotify_client_id,
                        "client_secret": settings.spotify_client_secret,
                    }
                )
                
                if response.status_code != 200:
                    logger.error(f"Error obteniendo tokens de Spotify: {response.text}")
                    raise HTTPException(status_code=400, detail="Error obteniendo tokens de Spotify")
                
                token_data = response.json()
                access_token = token_data["access_token"]
                refresh_token = token_data.get("refresh_token", "")
                expires_in = token_data.get("expires_in", 3600)
                expires_at = datetime.utcnow() + timedelta(seconds=expires_in)
                
                # Verificar usuario real de Spotify
                spotify_user = await _spotify_user_profile(access_token, strict=True)
                platform_user_id = spotify_user.get("id", "unknown")
                display_name = spotify_user.get("display_name") or platform_user_id

                # Update the main user display_name with Spotify's
                if display_name and display_name != platform_user_id:
                    user.display_name = display_name
                    db.commit()

                logger.info(f"Spotify OAuth exitoso para usuario: {platform_user_id} ({display_name})")
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error en OAuth de Spotify: {e}")
            raise HTTPException(status_code=500, detail="Error procesando la autenticación con Spotify.")
    else:
        # Mock para desarrollo o plataformas sin OAuth configurado
        access_token = f"{platform}_access_token"
        refresh_token = f"{platform}_refresh_token"
        expires_at = datetime.utcnow() + timedelta(hours=1)
        mock_profile = _mock_user_profile(platform)
        if mock_profile:
            platform_user_id = mock_profile.get("id", f"{platform}_user_123")
            display_name = mock_profile.get("display_name") or platform_user_id
        else:
            platform_user_id = f"{platform}_user_123"
            display_name = platform_user_id

    acct = db.query(UserStreamingAccount).filter_by(user_id=user.id, platform=platform).first()
    if not acct:
        acct = UserStreamingAccount(
            user_id=user.id,
            platform=platform,
            access_token=access_token,
            refresh_token=refresh_token,
            expires_at=expires_at,
            platform_user_id=platform_user_id,
        )
        db.add(acct)
    else:
        acct.access_token = access_token
        acct.refresh_token = refresh_token
        acct.expires_at = expires_at
        acct.platform_user_id = platform_user_id
    db.commit()

    # Mostrar página de éxito en lugar de redirigir
    # Esto funciona mejor para Flutter Desktop
    platform_names = {
        "spotify": "Spotify",
        "deezer": "Deezer",
        "apple": "Apple Music"
    }
    
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Autenticación Exitosa</title>
        <style>
            body {{
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                color: white;
            }}
            .container {{
                text-align: center;
                background: rgba(255, 255, 255, 0.1);
                backdrop-filter: blur(10px);
                padding: 40px;
                border-radius: 20px;
                box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
                border: 1px solid rgba(255, 255, 255, 0.18);
            }}
            .checkmark {{
                width: 80px;
                height: 80px;
                border-radius: 50%;
                display: inline-block;
                background: #1DB954;
                margin-bottom: 20px;
                position: relative;
            }}
            .checkmark::after {{
                content: '✓';
                position: absolute;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                font-size: 50px;
                color: white;
            }}
            h1 {{
                margin: 0 0 10px 0;
                font-size: 32px;
            }}
            p {{
                font-size: 18px;
                opacity: 0.9;
                margin: 10px 0;
            }}
            .platform {{
                font-weight: bold;
                color: #1DB954;
            }}
            .instruction {{
                margin-top: 30px;
                font-size: 14px;
                opacity: 0.7;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="checkmark"></div>
            <h1>¡Cuenta Vinculada!</h1>
            <p>Tu cuenta de <span class="platform">{platform_names.get(platform, platform)}</span> ha sido vinculada exitosamente.</p>
            <p class="instruction">Puedes cerrar esta ventana y volver a la aplicación.</p>
        </div>
        <script>
            // Auto-cerrar después de 3 segundos (opcional)
            setTimeout(() => {{
                window.close();
            }}, 3000);
        </script>
    </body>
    </html>
    """
    
    return HTMLResponse(content=html_content)


@app.post("/api/generate-playlist/facial")
async def generate_playlist_facial(
    image: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """
    Genera una playlist desde las liked songs del usuario
    filtradas por la emoción detectada en la foto.
    """
    user = get_current_user(None, db)

    # 1. Detectar emoción (stub → producción: DeepFace)
    content = await image.read()
    raw_emotion, _ = emotion_detector.detect_emotion_from_image(content)
    mood = EMOTION_ALIAS.get(raw_emotion, "neutral")

    # 2. Obtener token de Spotify
    spotify_account = db.query(UserStreamingAccount).filter_by(
        user_id=user.id, platform="spotify"
    ).first()

    tracks: List[Dict] = []
    total_analyzed = 0
    source = "internal"

    if spotify_account and spotify_account.access_token:
        try:
            token = await _get_spotify_token(db, user)
            rec = MoodRecommender(token)
            tracks, total_analyzed = await rec.generate_playlist(mood, playlist_size=25)
            source = "spotify_liked"
            logger.info(f"Facial ({mood}): {len(tracks)} canciones de {total_analyzed} liked songs")
        except Exception as e:
            logger.error(f"MoodRecommender falló en facial: {e}")
            tracks = HybridRecommender(user.id)._fake_tracks(mood)
    else:
        tracks = HybridRecommender(user.id)._fake_tracks(mood)
        logger.warning("Spotify no conectado — usando tracks de respaldo")

    # 3. Nombre de playlist
    import random as _rand
    names = MOOD_PLAYLIST_NAMES.get(mood, MOOD_PLAYLIST_NAMES["neutral"])
    playlist_name = _rand.choice(names)

    # 4. Guardar en BD
    ai_playlist = AIGeneratedPlaylist(
        user_id=user.id,
        playlist_name=playlist_name,
        generation_method="facial",
        emotion_detected=mood,
        prompt_used=f"Escaneo facial → {mood}",
        tracks=tracks,
        platform=source,
    )
    db.add(ai_playlist)
    db.commit()
    db.refresh(ai_playlist)

    return {
        "success": True,
        "playlist_id": ai_playlist.id,
        "playlist_name": playlist_name,
        "emotion_detected": mood,
        "tracks_count": len(tracks),
        "total_liked_analyzed": total_analyzed,
        "playlist": tracks,
    }


@app.post("/api/generate-playlist/prompt")
async def generate_playlist_prompt(
    payload: dict,
    db: Session = Depends(get_db)
):
    import json
    import re
    from collections import Counter
    from urllib.parse import quote
    from fastapi import HTTPException
    
    user = get_current_user(None, db)
    prompt = (payload or {}).get("prompt", "").strip()
    if not prompt:
        raise HTTPException(status_code=422, detail="prompt is required")

    analysis = prompt_processor.analyze_prompt(prompt)
    mood = analysis.get("mood", "neutral")
    
    openrouter_key = getattr(settings, 'openrouter_api_key', None)
    if not openrouter_key:
        raise HTTPException(status_code=500, detail="OPENROUTER_API_KEY no está configurada")

    spotify_account = db.query(UserStreamingAccount).filter_by(
        user_id=user.id, platform="spotify"
    ).first()
    
    if not spotify_account or not spotify_account.access_token:
        raise HTTPException(status_code=400, detail="Conecta tu cuenta de Spotify primero")

    token = await _get_spotify_token(db, user)
    
    # --- 1. EXTRAER EL GUSTO MUSICAL DEL USUARIO (AMPLIADO A 50 Y CON GÉNEROS) ---
    favorite_artists_str = "Varios"
    favorite_genres_str = "Variados"
    try:
        # Usamos medium_term (6 meses) y sacamos 50 artistas para tener un panorama gigante
        top_artists_data = await _spotify_api_request("/me/top/artists?limit=50&time_range=medium_term", token)
        artists_items = top_artists_data.get("items", [])
        
        if artists_items:
            # Sacamos los nombres
            artists_names = [a["name"] for a in artists_items]
            favorite_artists_str = ", ".join(artists_names)
            
            # Sacamos todos los géneros de esos artistas
            all_genres = []
            for a in artists_items:
                all_genres.extend(a.get("genres", []))
            
            # Obtenemos los 15 géneros más repetidos de tu perfil
            top_genres = [g for g, c in Counter(all_genres).most_common(15)]
            if top_genres:
                favorite_genres_str = ", ".join(top_genres)
                
    except Exception as e:
        logger.warning(f"No se pudieron obtener los artistas top: {e}")

    # --- 2. PEDIR A LA IA QUE INVENTE LA PLAYLIST ---
    system_prompt = (
        "Eres un curador musical experto. El usuario te dará un prompt (situación o mood).\n"
        "PERFIL DEL USUARIO:\n"
        f"- Artistas favoritos: {favorite_artists_str}.\n"
        f"- Géneros que suele escuchar: {favorite_genres_str}.\n\n"
        "INSTRUCCIONES ESTRICTAS:\n"
        "1. Genera EXACTAMENTE 50 canciones reales (pedimos 50 como margen de seguridad).\n"
        "2. PRIORIDAD MÁXIMA: El mood es la LEY. Si el prompt pide tristeza o calma, ESTÁ PROHIBIDO incluir canciones de fiesta, reguetón de discoteca o ritmos hype.\n"
        "3. BALANCE: Usa el perfil del usuario como inspiración. Si pide algo triste, busca temas melancólicos de sus artistas, o busca en sus géneros favoritos (ej. Pop latino triste) temas que SÍ encajen. No fuerces perreo donde no va.\n"
        "4. Devuelve ÚNICAMENTE un arreglo JSON puro con este formato:\n"
        '[{"title": "Nombre de la cancion", "artist": "Nombre del artista"}]\n'
        "Cero texto extra."
    )
    
    async with httpx.AsyncClient(timeout=90.0) as client:
        try:
            logger.info(f"Generando 50 canciones (Buffer) adaptadas a 50 artistas y sus géneros...")
            res = await client.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {openrouter_key}", 
                    "Content-Type": "application/json"
                },
                json={
                    "model": "minimax/minimax-m2.5:free", 
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": prompt}
                    ]
                }
            )
            
            if res.status_code != 200:
                raise HTTPException(status_code=500, detail="Error en la API de IA")
                
            response_data = res.json()
            if "choices" not in response_data:
                raise HTTPException(status_code=500, detail="La IA no devolvió el formato esperado")

            content = response_data["choices"][0]["message"]["content"]
            
            match = re.search(r'\[.*\]', content, re.DOTALL)
            if not match:
                logger.error(f"La IA no devolvió un JSON válido: {content}")
                raise HTTPException(status_code=500, detail="La IA no formateó bien el JSON.")
                
            clean_content = match.group(0)
            recommended_songs = json.loads(clean_content)
            logger.info(f"La IA sugirió {len(recommended_songs)} canciones. Buscando en Spotify...")
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error con OpenRouter: {e}")
            raise HTTPException(status_code=500, detail="Error generando recomendaciones con IA")

    # --- 3. BUSCAR LAS CANCIONES EN SPOTIFY ---
    playlist_tracks = []
    
    for song in recommended_songs:
        # Paramos si ya llegamos a las 40 perfectas
        if len(playlist_tracks) >= 40:
            break
            
        try:
            title = song.get("title", "")
            artist = song.get("artist", "")
            
            query = quote(f"track:{title} artist:{artist}")
            search_data = await _spotify_api_request(f"/search?q={query}&type=track&limit=1", token)
            
            items = search_data.get("tracks", {}).get("items", [])
            if items:
                track_data = items[0]
                # Verificación extra opcional: no meter la misma canción dos veces
                if not any(t["spotify_id"] == track_data.get("id") for t in playlist_tracks):
                    playlist_tracks.append({
                        "spotify_id": track_data.get("id"),
                        "title": track_data.get("name"),
                        "artist": ", ".join(a.get("name", "") for a in track_data.get("artists", [])),
                        "album": track_data.get("album", {}).get("name"),
                        "image_url": track_data.get("album", {}).get("images", [{}])[0].get("url") if track_data.get("album", {}).get("images") else None,
                        "uri": track_data.get("uri"),
                        "external_urls": track_data.get("external_urls", {})
                    })
        except Exception as e:
            logger.warning(f"No se encontró en Spotify: {song.get('title')} - {song.get('artist')}")

    # --- 4. GUARDAR EN BD ---
    playlist_name = MoodRecommender.playlist_name_for_mood(mood, prompt)

    ai_playlist = AIGeneratedPlaylist(
        user_id=user.id,
        playlist_name=playlist_name,
        generation_method="prompt",
        emotion_detected=mood,
        prompt_used=prompt,
        tracks=playlist_tracks, 
        platform="spotify_ai_hybrid",
    )
    db.add(ai_playlist)
    db.commit()
    db.refresh(ai_playlist)

    return {
        "success": True,
        "playlist_id": ai_playlist.id,
        "playlist_name": playlist_name,
        "analysis": analysis,
        "tracks_count": len(playlist_tracks),
        "source": "spotify_ai_hybrid",
        "playlist": playlist_tracks,
    }


def _generate_playlist_name(prompt: str, emotion: str, genres: List[str], activity: str = None) -> str:
    """Genera un nombre atractivo para la playlist"""
    # Si el prompt es corto y descriptivo, usarlo
    if len(prompt) <= 40:
        return prompt.title()
    
    # Generar nombre basado en contexto
    if activity:
        activity_names = {
            'study': 'Focus & Study Mix',
            'workout': 'Workout Power Mix',
            'sleep': 'Sleep & Relax',
            'party': 'Party Vibes',
            'travel': 'Road Trip Mix'
        }
        if activity in activity_names:
            return activity_names[activity]
    
    # Nombre basado en emoción y género
    emotion_names = {
        'happy': 'Happy',
        'sad': 'Melancholic',
        'angry': 'Intense',
        'calm': 'Chill',
        'romantic': 'Romantic',
        'energetic': 'Energetic'
    }
    
    emotion_label = emotion_names.get(emotion, 'Mix')
    genre_label = genres[0].title() if genres else 'Music'
    
    return f"{emotion_label} {genre_label} Mix"


# ============================================================================
# ENDPOINTS DE PLAYLISTS GENERADAS
# ============================================================================

@app.get("/api/playlists/generated")
def get_generated_playlists(db: Session = Depends(get_db)):
    """Obtener todas las playlists generadas por IA del usuario"""
    user = get_current_user(None, db)
    playlists = db.query(AIGeneratedPlaylist).filter_by(user_id=user.id).order_by(
        AIGeneratedPlaylist.created_at.desc()
    ).all()
    
    return {
        "success": True,
        "count": len(playlists),
        "playlists": [
            {
                "id": p.id,
                "name": p.playlist_name,
                "generation_method": p.generation_method,
                "emotion": p.emotion_detected,
                "prompt": p.prompt_used,
                "tracks_count": len(p.tracks) if p.tracks else 0,
                "platform": p.platform,
                "created_at": p.created_at.isoformat() if p.created_at else None
            }
            for p in playlists
        ]
    }


@app.get("/api/playlists/generated/{playlist_id}")
def get_generated_playlist_detail(playlist_id: int, db: Session = Depends(get_db)):
    """Obtener detalles completos de una playlist generada"""
    user = get_current_user(None, db)
    playlist = db.query(AIGeneratedPlaylist).filter_by(
        id=playlist_id,
        user_id=user.id
    ).first()
    
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist no encontrada")
    
    return {
        "success": True,
        "playlist": {
            "id": playlist.id,
            "name": playlist.playlist_name,
            "generation_method": playlist.generation_method,
            "emotion": playlist.emotion_detected,
            "prompt": playlist.prompt_used,
            "tracks": playlist.tracks,
            "platform": playlist.platform,
            "created_at": playlist.created_at.isoformat() if playlist.created_at else None
        }
    }


@app.get("/api/playlists/generated/{playlist_id}")
def get_generated_playlist_detail(playlist_id: int, db: Session = Depends(get_db)):
    """Obtener detalles completos de una playlist generada"""
    user = get_current_user(None, db)
    playlist = db.query(AIGeneratedPlaylist).filter_by(
        id=playlist_id,
        user_id=user.id
    ).first()
    
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist no encontrada")
    
    # --- PARCHE DE SEGURIDAD PARA FLUTTER ---
    # Extraemos la lista sin importar cómo se haya guardado en SQLite
    tracks_list = []
    if isinstance(playlist.tracks, list):
        tracks_list = playlist.tracks
    elif isinstance(playlist.tracks, dict):
        tracks_list = playlist.tracks.get("items", [])
    
    return {
        "success": True,
        "playlist": {
            "id": playlist.id,
            "name": playlist.playlist_name,
            "generation_method": playlist.generation_method,
            "emotion": playlist.emotion_detected,
            "prompt": playlist.prompt_used,
            "tracks": tracks_list,  # <-- Flutter ahora SIEMPRE recibirá una lista feliz
            "platform": playlist.platform,
            "created_at": playlist.created_at.isoformat() if playlist.created_at else None
        }
    }

@app.delete("/api/playlists/generated/{playlist_id}")
def delete_generated_playlist(playlist_id: int, db: Session = Depends(get_db)):
    """Eliminar una playlist generada con IA"""
    from fastapi import HTTPException
    
    # 1. Obtener al usuario actual por seguridad
    user = get_current_user(None, db)
    
    # 2. Buscar la playlist asegurando que le pertenezca al usuario
    playlist = db.query(AIGeneratedPlaylist).filter_by(
        id=playlist_id,
        user_id=user.id
    ).first()
    
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist no encontrada")
    
    # 3. Eliminar de la base de datos
    db.delete(playlist)
    db.commit()
    
    return {"success": True, "message": "Playlist eliminada correctamente"}

# ============================================================================
# ENDPOINTS DE DEEZER Y APPLE MUSIC (deshabilitados para versiones futuras)
# ============================================================================
# Estos endpoints han sido comentados porque actualmente solo se usa Spotify.
# Se rehabilitarán en versiones futuras de la app.


# ============================================================================
# ENDPOINTS DE PERFIL Y COMUNIDAD
# ============================================================================

from pydantic import BaseModel as PydanticBaseModel
from typing import Optional as Opt

class UserProfileUpdate(PydanticBaseModel):
    display_name: Opt[str] = None
    dob: Opt[str] = None
    gender: Opt[str] = None

@app.get("/me/profile")
async def get_user_profile(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Try to enrich with live Spotify data
    spotify_acct = db.query(UserStreamingAccount).filter_by(user_id=user.id, platform="spotify").first()
    spotify_name = user.display_name
    spotify_avatar = None

    if spotify_acct and spotify_acct.access_token:
        try:
            sp_profile = await _spotify_user_profile(spotify_acct.access_token, strict=False)
            if sp_profile:
                live_name = sp_profile.get("display_name") or spotify_name
                # Sync display_name into DB if it changed
                if live_name and live_name != user.display_name:
                    user.display_name = live_name
                    db.commit()
                spotify_name = live_name
                images = sp_profile.get("images", [])
                if images:
                    spotify_avatar = images[0].get("url")
        except Exception:
            pass  # Use stored values as fallback

    return {
        "id": user.id,
        "email": user.email,
        "display_name": spotify_name or user.display_name,
        "dob": getattr(user, 'dob', None),
        "gender": getattr(user, 'gender', None),
        "avatar_url": spotify_avatar,
        "created_at": str(user.created_at) if user.created_at else None
    }

@app.put("/me/profile")
async def update_user_profile(profile: UserProfileUpdate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if profile.display_name is not None:
        user.display_name = profile.display_name
    if profile.dob is not None:
        user.dob = profile.dob
    if profile.gender is not None:
        user.gender = profile.gender
    db.commit()
    db.refresh(user)
    return {
        "id": user.id,
        "email": user.email,
        "display_name": user.display_name,
        "dob": getattr(user, 'dob', None),
        "gender": getattr(user, 'gender', None)
    }

@app.get("/api/playlists/community")
async def get_community_playlists(db: Session = Depends(get_db)):
    playlists = db.query(AIGeneratedPlaylist).order_by(AIGeneratedPlaylist.created_at.desc()).limit(20).all()
    results = []
    for p in playlists:
        u = db.query(User).filter(User.id == p.user_id).first()
        author_name = u.display_name if u and u.display_name else "Usuario Anónimo"
        
        tracks_list = []
        if isinstance(p.tracks, dict) and "items" in p.tracks:
            tracks_list = p.tracks["items"]
        elif isinstance(p.tracks, list):
            tracks_list = p.tracks

        results.append({
            "id": p.id,
            "name": p.playlist_name,
            "method": p.generation_method,
            "emotion": p.emotion_detected,
            "platform": p.platform,
            "tracks_count": len(tracks_list),
            "author": author_name,
            "created_at": p.created_at.isoformat() if p.created_at else None
        })
    return {"playlists": results}


# ============================================================================
# ENDPOINTS DE SPOTIFY API (Proxy)
# ============================================================================

async def _get_spotify_token(db: Session, user: User) -> str:
    """Obtener token de acceso de Spotify. Refresca automáticamente si expiró."""
    if not settings.spotify_client_id or not settings.spotify_client_secret:
        raise HTTPException(
            status_code=500,
            detail="Spotify OAuth no está configurado correctamente en .env.",
        )
 
    user = get_current_user(None, db)
    account = db.query(UserStreamingAccount).filter_by(
        user_id=user.id, platform="spotify"
    ).first()
 
    if not account:
        raise HTTPException(status_code=401, detail="Spotify no conectado")
 
    token = account.access_token
 
    # Rechazar tokens mock (de desarrollo)
    if token.startswith("spotify_"):
        raise HTTPException(
            status_code=401,
            detail="Token de Spotify inválido. Vuelve a autenticar con la API oficial.",
        )
 
    # FIX: Refrescar automáticamente si el token expiró o está por expirar (margen de 5 min)
    margen = timedelta(minutes=5)
    if account.expires_at and datetime.utcnow() >= (account.expires_at - margen):
        logger.warning(f"Token expirado o por vencer (expires_at={account.expires_at}). Refrescando...")
        token = await _refresh_spotify_token(db, account)
 
    return token

async def _refresh_spotify_token(db: Session, account) -> str:
    """Refresca el access token usando el refresh token guardado en DB."""
    if not account.refresh_token:
        raise HTTPException(
            status_code=401,
            detail="Token de Spotify expirado y no hay refresh token. Vuelve a autenticar."
        )
 
    logger.info("Intentando refrescar token de Spotify...")
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://accounts.spotify.com/api/token",
                data={
                    "grant_type": "refresh_token",
                    "refresh_token": account.refresh_token,
                    "client_id": settings.spotify_client_id,
                    "client_secret": settings.spotify_client_secret,
                },
            )
 
        if response.status_code != 200:
            logger.error(f"Error al refrescar token: {response.status_code} - {response.text}")
            raise HTTPException(
                status_code=401,
                detail="No se pudo refrescar el token de Spotify. Vuelve a autenticar.",
            )
 
        token_data = response.json()
        new_token = token_data["access_token"]
        expires_in = token_data.get("expires_in", 3600)
 
        # Actualizar en base de datos
        account.access_token = new_token
        account.expires_at = datetime.utcnow() + timedelta(seconds=expires_in)
        # Spotify a veces rota el refresh token también
        if "refresh_token" in token_data:
            account.refresh_token = token_data["refresh_token"]
        db.commit()
 
        logger.info("Token de Spotify refrescado exitosamente ✓")
        return new_token
 
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Excepción refrescando token: {e}")
        raise HTTPException(status_code=401, detail="Error inesperado refrescando el token de Spotify.")


async def _spotify_api_request(
    endpoint: str, token: str, method: str = "GET", data: dict = None
):
    """Hacer una petición autenticada a la API de Spotify con validación de respuesta."""
    url = f"https://api.spotify.com/v1{endpoint}"
    headers = {"Authorization": f"Bearer {token}"}
 
    async with httpx.AsyncClient(timeout=15.0) as client:
        if method == "GET":
            response = await client.get(url, headers=headers)
        elif method == "POST":
            response = await client.post(url, headers=headers, json=data)
        elif method == "PUT":
            response = await client.put(url, headers=headers, json=data)
        elif method == "DELETE":
            response = await client.delete(url, headers=headers)
        else:
            raise ValueError(f"Método HTTP no soportado: {method}")
 
    # Errores HTTP estándar
    if response.status_code == 401:
        raise HTTPException(status_code=401, detail="Token de Spotify inválido o expirado")
 
    if response.status_code >= 400:
        logger.error(f"Error Spotify API [{response.status_code}] {endpoint}: {response.text}")
        raise HTTPException(
            status_code=response.status_code,
            detail=f"Error de Spotify: {response.text}",
        )
 
    result = response.json()
 
    # FIX CLAVE: Spotify a veces devuelve 200 OK con un cuerpo de error.
    # Ej: {"error": {"status": 400, "message": "..."}}
    # Si esto pasa, lo tratamos como error real.
    if isinstance(result, dict) and "error" in result:
        error_info = result["error"]
        error_status = error_info.get("status", 400) if isinstance(error_info, dict) else 400
        error_msg = error_info.get("message", str(error_info)) if isinstance(error_info, dict) else str(error_info)
        logger.error(f"Spotify devolvió error en cuerpo 200 [{endpoint}]: {error_status} - {error_msg}")
        raise HTTPException(
            status_code=error_status,
            detail=f"Error de Spotify (200 con error): {error_msg}",
        )
 
    return result

async def _get_lastfm_artist_data(artist_name: str) -> dict:
    """Obtiene géneros y listeners de Last.fm como fallback de Spotify."""
    if not settings.lastfm_api_key:
        logger.warning("LASTFM_API_KEY no configurada, saltando enriquecimiento.")
        return {}

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            res = await client.get(
                "https://ws.audioscrobbler.com/2.0/",
                params={
                    "method": "artist.getinfo",
                    "artist": artist_name,
                    "api_key": settings.lastfm_api_key,
                    "format": "json",
                },
            )

        if res.status_code != 200:
            logger.warning(f"Last.fm respondió {res.status_code} para '{artist_name}'")
            return {}

        data = res.json()

        # Si Last.fm no encontró al artista
        if "error" in data:
            logger.warning(f"Last.fm error para '{artist_name}': {data.get('message')}")
            return {}

        artist = data.get("artist", {})

        # Extraer tags como géneros
        tags_raw = artist.get("tags", {}).get("tag", [])
        genres = [t["name"] for t in tags_raw if isinstance(t, dict)]

        # Listeners como sustituto de followers
        listeners = int(artist.get("stats", {}).get("listeners", 0))

        logger.info(f"Last.fm para '{artist_name}': genres={genres}, listeners={listeners}")

        return {
            "genres": genres,
            "followers": {"total": listeners},
        }

    except Exception as e:
        logger.error(f"Error consultando Last.fm para '{artist_name}': {e}")
        return {}


@app.get("/spotify/me")
async def spotify_get_profile(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Obtener perfil del usuario de Spotify"""
    token = await _get_spotify_token(db, user)
    return await _spotify_api_request("/me", token)


@app.get("/spotify/me/playlists")
async def spotify_get_playlists(user: User = Depends(get_current_user), db: Session = Depends(get_db), limit: int = 50):
    """Obtener playlists del usuario"""
    token = await _get_spotify_token(db, user)
    return await _spotify_api_request(f"/me/playlists?limit={limit}", token)


@app.get("/spotify/me/top/tracks")
async def spotify_get_top_tracks(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = 50,
    time_range: str = "medium_term"
):
    """Obtener canciones favoritas del usuario"""
    token = await _get_spotify_token(db, user)
    return await _spotify_api_request(
        f"/me/top/tracks?limit={limit}&time_range={time_range}",
        token
    )


@app.get("/spotify/me/top/artists")
async def spotify_get_top_artists(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = 50,
    time_range: str = "medium_term"
):
    """Obtener artistas favoritos del usuario"""
    token = await _get_spotify_token(db, user)
    return await _spotify_api_request(
        f"/me/top/artists?limit={limit}&time_range={time_range}",
        token
    )


@app.get("/spotify/me/tracks")
async def spotify_get_saved_tracks(user: User = Depends(get_current_user), db: Session = Depends(get_db), limit: int = 50):
    """Obtener canciones guardadas (liked songs)"""
    token = await _get_spotify_token(db, user)
    return await _spotify_api_request(f"/me/tracks?limit={limit}", token)


@app.get("/spotify/me/player/recently-played")
async def spotify_get_recently_played(user: User = Depends(get_current_user), db: Session = Depends(get_db), limit: int = 50):
    """Obtener canciones recientemente reproducidas"""
    token = await _get_spotify_token(db, user)
    return await _spotify_api_request(
        f"/me/player/recently-played?limit={limit}",
        token
    )


@app.get("/spotify/playlists/{playlist_id}")
async def spotify_get_playlist(playlist_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Obtener detalles de una playlist y asegurar que traiga las canciones con la nueva API"""
    token = await _get_spotify_token(db, user)
    
    try:
        playlist_data = await _spotify_api_request(f"/playlists/{playlist_id}", token)
        
        # Validamos si Spotify ya incluyó las canciones en el primer intento
        has_songs = False
        if "items" in playlist_data and "items" in playlist_data["items"]:
            if len(playlist_data["items"]["items"]) > 0:
                has_songs = True
        elif "tracks" in playlist_data and "items" in playlist_data.get("tracks", {}):
            if len(playlist_data["tracks"]["items"]) > 0:
                has_songs = True

        if not has_songs:
            # EL GRAN SECRETO: Spotify eliminó /tracks. Ahora usamos /items
            tracks_data = await _spotify_api_request(f"/playlists/{playlist_id}/items?limit=100", token)
            
            if "tracks" not in playlist_data:
                playlist_data["tracks"] = {}
                
            # Inyectamos los resultados para que Flutter los reciba perfectamente
            if isinstance(tracks_data, dict) and "items" in tracks_data:
                playlist_data["tracks"]["items"] = tracks_data["items"]
            elif isinstance(tracks_data, list):
                playlist_data["tracks"]["items"] = tracks_data
            else:
                playlist_data["tracks"]["items"] = []
                
        return playlist_data
        
    except Exception as e:
        logger.error(f"====== ERROR LEYENDO PLAYLIST {playlist_id} ======\nDetalle: {e}")
        if "playlist_data" in locals() and isinstance(playlist_data, dict):
            if "tracks" not in playlist_data:
                playlist_data["tracks"] = {"items": []}
            return playlist_data
        return {"id": playlist_id, "name": "Playlist", "tracks": {"items": []}}


@app.get("/spotify/search")
async def spotify_search(
    q: str,
    user: User = Depends(get_current_user),
    type: str = "track,artist,album",
    limit: int = 20,
    db: Session = Depends(get_db)
):
    """Buscar en Spotify"""
    token = await _get_spotify_token(db, user)
    query = quote(q)
    return await _spotify_api_request(
        f"/search?q={query}&type={type}&limit={limit}",
        token
    )

@app.get("/spotify/artists/{artist_id}")
async def spotify_get_artist(artist_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Obtener expediente completo de un artista, enriquecido con Last.fm."""
    token = await _get_spotify_token(db, user)
    data = await _spotify_api_request(f"/artists/{artist_id}", token)

    # Si Spotify devuelve objeto simplificado (sin géneros/seguidores),
    # enriquecer con Last.fm
    if not data.get("genres") and not data.get("followers"):
        artist_name = data.get("name", "")
        logger.info(f"Spotify devolvió objeto simplificado para '{artist_name}', consultando Last.fm...")
        lastfm_data = await _get_lastfm_artist_data(artist_name)
        if lastfm_data:
            data = {**data, **lastfm_data}

    logger.info(
        f"Artist {artist_id} → followers={data.get('followers')}, genres={data.get('genres')}"
    )
    return data

@app.get("/spotify/artists/{artist_id}/user-playlists")
async def spotify_get_artist_user_playlists(artist_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    token = await _get_spotify_token(db, user)

    me = await _spotify_api_request("/me", token)
    my_id = me.get("id")

    playlists_data = await _spotify_api_request("/me/playlists?limit=50", token)
    playlists = playlists_data.get("items", [])
    logger.info(f"Total playlists (propias + seguidas): {len(playlists)}")

    matching = []

    for playlist in playlists:
        playlist_id = playlist.get("id")
        playlist_name = playlist.get("name", "?")
        owner_id = playlist.get("owner", {}).get("id")
        is_own = owner_id == my_id

        if not playlist_id:
            continue

        try:
            found = False
            next_url = f"/playlists/{playlist_id}/items?limit=100"

            while next_url and not found:
                    tracks_data = await _spotify_api_request(next_url, token)
                    items = tracks_data.get("items", [])

                    for item in items:
                        if not item:
                            continue
                        track = item.get("track")
                        if not track or track.get("type") == "episode":
                            continue
                        artists = track.get("artists") or []
                        if any(a.get("id") == artist_id for a in artists):
                            found = True
                            break

                    raw_next = tracks_data.get("next")
                    # ===== CORRECCIÓN A PRUEBA DE BALAS PARA LA PAGINACIÓN =====
                    if raw_next and not found:
                        # Cortamos la URL exactamente donde empieza el endpoint
                        if "/v1" in raw_next:
                            next_url = raw_next.split("/v1")[-1]
                        else:
                            next_url = None
                    else:
                        next_url = None
            if found:
                logger.info(f"  ✓ '{playlist_name}' ({'propia' if is_own else 'seguida'})")
                matching.append({
                    "id": playlist_id,
                    "name": playlist_name,
                    "description": playlist.get("description", ""),
                    "images": playlist.get("images", []),
                    "tracks_total": playlist.get("tracks", {}).get("total", 0),
                    "external_urls": playlist.get("external_urls", {}),
                    "is_own": is_own,  # útil para mostrar un ícono diferente en Flutter
                })
            else:
                logger.info(f"  ✗ '{playlist_name}'")

        except Exception as e:
            # 403 = playlist privada de otro usuario, simplemente se omite
            status = str(e)[:3]
            if "403" in status:
                logger.info(f"  — '{playlist_name}' privada, sin acceso (403)")
            elif "502" in status:
                logger.warning(f"  — '{playlist_name}' error temporal de Spotify (502)")
            else:
                logger.warning(f"  — '{playlist_name}' error: {e}")
            continue

    logger.info(f"Resultado: {len(matching)} playlists con artista {artist_id}")
    return {"playlists": matching}

@app.get("/spotify/artists/{artist_id}/top-tracks")
async def spotify_get_artist_top_tracks(artist_id: str, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    token = await _get_spotify_token(db, user)

    # Nombre del artista
    artist_data = await _spotify_api_request(f"/artists/{artist_id}", token)
    artist_name = artist_data.get("name", "")

    # Top tracks de Last.fm
    raw_tracks = []
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            res = await client.get(
                "https://ws.audioscrobbler.com/2.0/",
                params={
                    "method": "artist.gettoptracks",
                    "artist": artist_name,
                    "api_key": settings.lastfm_api_key,
                    "format": "json",
                    "limit": 5,  # solo 5
                },
            )
        if res.status_code == 200:
            raw_tracks = res.json().get("toptracks", {}).get("track", [])
        else:
            logger.warning(f"Last.fm API error: {res.status_code}")
    except Exception as e:
        logger.error(f"Error consultando top tracks en Last.fm para '{artist_name}': {e}")

    # Enriquecer cada track con imagen real de Spotify
    tracks = []
    for t in raw_tracks:
        track_name = t.get("name", "")
        playcount = int(t.get("playcount", 0))
        image_url = None

        try:
            # Buscar el track en Spotify para obtener la portada del álbum
            query = quote(f"track:{track_name} artist:{artist_name}")
            search = await _spotify_api_request(
                f"/search?q={query}&type=track&limit=1", token
            )
            items = search.get("tracks", {}).get("items", [])
            if items:
                album_images = items[0].get("album", {}).get("images", [])
                if album_images:
                    image_url = album_images[0].get("url")
        except Exception:
            pass  # Si falla la búsqueda, queda sin imagen

        tracks.append({
            "name": track_name,
            "playcount": playcount,
            "image_url": image_url,
        })

    logger.info(f"Top 5 tracks de '{artist_name}' con imágenes de Spotify")
    return {"tracks": tracks}