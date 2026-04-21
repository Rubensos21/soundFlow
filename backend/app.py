from urllib.parse import quote
from fastapi import FastAPI, Depends, Request, UploadFile, File, HTTPException
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
from .ai import EmotionDetector, PromptProcessor, HybridRecommender


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


PLATFORMS = {"spotify", "deezer", "apple"}

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


def _get_or_create_demo_user(db: Session) -> User:
    user = db.query(User).filter_by(email="demo@soundflow.app").first()
    if not user:
        user = User(email="demo@soundflow.app", display_name="Demo User")
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
    user = _get_or_create_demo_user(db)
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
    user = _get_or_create_demo_user(db)
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
def auth_redirect(platform: str):
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
        
        return RedirectResponse(url=auth_url)
    
    # Para otras plataformas, usar mock por ahora
    return RedirectResponse(url=f"/auth/{platform}/callback?code=mock_code&state=mock_state")


@app.get("/auth/{platform}/callback")
async def auth_callback(platform: str, code: str = None, error: str = None, db: Session = Depends(get_db)):
    if platform not in PLATFORMS:
        raise HTTPException(status_code=400, detail="unsupported platform")
    
    if error:
        logger.error(f"Error en OAuth {platform}: {error}")
        return HTMLResponse(content=f"<h1>Error: {error}</h1>")

    user = _get_or_create_demo_user(db)

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
async def generate_playlist_facial(image: UploadFile = File(...), db: Session = Depends(get_db)):
    user = _get_or_create_demo_user(db)
    content = await image.read()
    emotion, suggested = emotion_detector.detect_emotion_from_image(content)
    recommender = HybridRecommender(user.id)
    playlist = recommender.generate_playlist_based_on_emotion(emotion, confidence=0.8)
    return {"success": True, "emotion_detected": emotion, "tracks_count": len(playlist), "playlist": playlist}


@app.post("/api/generate-playlist/prompt")
async def generate_playlist_prompt(payload: dict, db: Session = Depends(get_db)):
    user = _get_or_create_demo_user(db)
    prompt = (payload or {}).get("prompt", "").strip()
    if not prompt:
        raise HTTPException(status_code=422, detail="prompt is required")
    
    # Analizar el prompt
    analysis = prompt_processor.analyze_prompt(prompt)
    logger.info(f"Análisis del prompt: {analysis}")
    
    # Intentar usar Spotify si está conectado
    spotify_account = db.query(UserStreamingAccount).filter_by(
        user_id=user.id,
        platform="spotify"
    ).first()
    
    recommender = HybridRecommender(user.id)
    playlist_tracks = []
    
    if spotify_account and spotify_account.access_token:
        # Generar playlist REAL desde Spotify
        try:
            playlist_tracks = await recommender.generate_playlist_from_spotify(
                analysis,
                spotify_account.access_token,
                limit=30
            )
            logger.info(f"Generadas {len(playlist_tracks)} canciones desde Spotify")
        except Exception as e:
            logger.error(f"Error generando desde Spotify: {e}")
            playlist_tracks = recommender.generate_playlist_from_prompt(analysis)
    else:
        # Fallback a playlist sintética
        playlist_tracks = recommender.generate_playlist_from_prompt(analysis)
        logger.info("Usando playlist sintética (Spotify no conectado)")
    
    # Generar nombre de playlist basado en el análisis
    emotion = analysis.get('emotion', 'neutral')
    genres = analysis.get('mentioned_genres', [])
    activity = analysis.get('activity')
    
    playlist_name = _generate_playlist_name(prompt, emotion, genres, activity)
    
    # Guardar playlist en la base de datos
    ai_playlist = AIGeneratedPlaylist(
        user_id=user.id,
        playlist_name=playlist_name,
        generation_method='prompt',
        emotion_detected=emotion,
        prompt_used=prompt,
        tracks=playlist_tracks,  # Guardar como JSON
        platform='spotify' if spotify_account else 'internal'
    )
    db.add(ai_playlist)
    db.commit()
    db.refresh(ai_playlist)
    
    logger.info(f"Playlist '{playlist_name}' guardada con ID: {ai_playlist.id}")
    
    return {
        "success": True,
        "playlist_id": ai_playlist.id,
        "playlist_name": playlist_name,
        "analysis": analysis,
        "tracks_count": len(playlist_tracks),
        "playlist": playlist_tracks
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
    user = _get_or_create_demo_user(db)
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
    user = _get_or_create_demo_user(db)
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


@app.delete("/api/playlists/generated/{playlist_id}")
def delete_generated_playlist(playlist_id: int, db: Session = Depends(get_db)):
    """Eliminar una playlist generada"""
    user = _get_or_create_demo_user(db)
    playlist = db.query(AIGeneratedPlaylist).filter_by(
        id=playlist_id,
        user_id=user.id
    ).first()
    
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist no encontrada")
    
    db.delete(playlist)
    db.commit()
    
    return {"success": True, "message": "Playlist eliminada"}


# ============================================================================
# ENDPOINTS DE DEEZER (Mock)
# ============================================================================


@app.get("/deezer/me")
def deezer_get_profile(db: Session = Depends(get_db)):
    """Obtener perfil del usuario de Deezer (Mock)"""
    _ensure_platform_linked(db, "deezer")
    return _get_mock_streaming_response("deezer", "profile")


@app.get("/deezer/me/playlists")
def deezer_get_playlists(db: Session = Depends(get_db)):
    """Obtener playlists del usuario de Deezer (Mock)"""
    _ensure_platform_linked(db, "deezer")
    return _get_mock_streaming_response("deezer", "playlists")


@app.get("/deezer/me/top/tracks")
def deezer_get_top_tracks(db: Session = Depends(get_db)):
    """Obtener canciones favoritas del usuario de Deezer (Mock)"""
    _ensure_platform_linked(db, "deezer")
    return _get_mock_streaming_response("deezer", "top_tracks")


@app.get("/deezer/me/player/recently-played")
def deezer_recently_played(db: Session = Depends(get_db)):
    """Obtener canciones recientemente reproducidas en Deezer (Mock)"""
    _ensure_platform_linked(db, "deezer")
    return _get_mock_streaming_response("deezer", "recently_played")


# ============================================================================
# ENDPOINTS DE APPLE MUSIC (Mock)
# ============================================================================


@app.get("/apple/me")
def apple_get_profile(db: Session = Depends(get_db)):
    """Obtener perfil del usuario de Apple Music (Mock)"""
    _ensure_platform_linked(db, "apple")
    return _get_mock_streaming_response("apple", "profile")


@app.get("/apple/me/playlists")
def apple_get_playlists(db: Session = Depends(get_db)):
    """Obtener playlists del usuario de Apple Music (Mock)"""
    _ensure_platform_linked(db, "apple")
    return _get_mock_streaming_response("apple", "playlists")


@app.get("/apple/me/top/tracks")
def apple_get_top_tracks(db: Session = Depends(get_db)):
    """Obtener canciones favoritas del usuario de Apple Music (Mock)"""
    _ensure_platform_linked(db, "apple")
    return _get_mock_streaming_response("apple", "top_tracks")


@app.get("/apple/me/player/recently-played")
def apple_recently_played(db: Session = Depends(get_db)):
    """Obtener canciones recientemente reproducidas en Apple Music (Mock)"""
    _ensure_platform_linked(db, "apple")
    return _get_mock_streaming_response("apple", "recently_played")


# ============================================================================
# ENDPOINTS DE SPOTIFY API (Proxy)
# ============================================================================

async def _get_spotify_token(db: Session) -> str:
    """Obtener token de acceso de Spotify del usuario demo"""
    if not settings.spotify_client_id or not settings.spotify_client_secret:
        raise HTTPException(
            status_code=500,
            detail="Spotify OAuth no está configurado correctamente en .env.",
        )
    user = _get_or_create_demo_user(db)
    account = db.query(UserStreamingAccount).filter_by(
        user_id=user.id,
        platform="spotify"
    ).first()
    
    if not account:
        raise HTTPException(status_code=401, detail="Spotify no conectado")
    
    # Verificar si el token está expirado
    if account.expires_at and datetime.utcnow() >= account.expires_at:
        # Aquí deberías refrescar el token
        # Por ahora, simplemente notificamos que expiró
        logger.warning("Token de Spotify expirado, requiere re-autenticación")
        if not settings.spotify_client_id:
            # Si es un token mock, no importa que esté expirado
            return account.access_token
        # Si es real y expiró, intentar refrescar
        # TODO: Implementar refresh token
        raise HTTPException(status_code=401, detail="Token de Spotify expirado")
    
    token = account.access_token
    if token.startswith("spotify_"):
        raise HTTPException(status_code=401, detail="Token de Spotify inválido. Vuelve a autenticar con la API oficial.")
    
    return token


async def _spotify_api_request(endpoint: str, token: str, method: str = "GET", data: dict = None):
    """Hacer una petición a la API de Spotify"""
    # Escribe la URL oficial: api . spotify . com
    url = f"https://api.spotify.com/v1{endpoint}"
    headers = {"Authorization": f"Bearer {token}"}
    
    async with httpx.AsyncClient() as client:
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
        
        if response.status_code == 401:
            raise HTTPException(status_code=401, detail="Token de Spotify inválido")
        
        if response.status_code >= 400:
            logger.error(f"Error de Spotify API: {response.status_code} - {response.text}")
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Error de Spotify: {response.text}"
            )
        
        return response.json()


@app.get("/spotify/me")
async def spotify_get_profile(db: Session = Depends(get_db)):
    """Obtener perfil del usuario de Spotify"""
    token = await _get_spotify_token(db)
    return await _spotify_api_request("/me", token)


@app.get("/spotify/me/playlists")
async def spotify_get_playlists(db: Session = Depends(get_db), limit: int = 50):
    """Obtener playlists del usuario"""
    token = await _get_spotify_token(db)
    return await _spotify_api_request(f"/me/playlists?limit={limit}", token)


@app.get("/spotify/me/top/tracks")
async def spotify_get_top_tracks(
    db: Session = Depends(get_db),
    limit: int = 50,
    time_range: str = "medium_term"
):
    """Obtener canciones favoritas del usuario"""
    token = await _get_spotify_token(db)
    return await _spotify_api_request(
        f"/me/top/tracks?limit={limit}&time_range={time_range}",
        token
    )


@app.get("/spotify/me/top/artists")
async def spotify_get_top_artists(
    db: Session = Depends(get_db),
    limit: int = 50,
    time_range: str = "medium_term"
):
    """Obtener artistas favoritos del usuario"""
    token = await _get_spotify_token(db)
    return await _spotify_api_request(
        f"/me/top/artists?limit={limit}&time_range={time_range}",
        token
    )


@app.get("/spotify/me/tracks")
async def spotify_get_saved_tracks(db: Session = Depends(get_db), limit: int = 50):
    """Obtener canciones guardadas (liked songs)"""
    token = await _get_spotify_token(db)
    return await _spotify_api_request(f"/me/tracks?limit={limit}", token)


@app.get("/spotify/me/player/recently-played")
async def spotify_get_recently_played(db: Session = Depends(get_db), limit: int = 50):
    """Obtener canciones recientemente reproducidas"""
    token = await _get_spotify_token(db)
    return await _spotify_api_request(
        f"/me/player/recently-played?limit={limit}",
        token
    )


@app.get("/spotify/playlists/{playlist_id}")
async def spotify_get_playlist(playlist_id: str, db: Session = Depends(get_db)):
    """Obtener detalles de una playlist y asegurar que traiga las canciones con la nueva API"""
    token = await _get_spotify_token(db)
    
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
    type: str = "track,artist,album",
    limit: int = 20,
    db: Session = Depends(get_db)
):
    """Buscar en Spotify"""
    token = await _get_spotify_token(db)
    query = quote(q)
    return await _spotify_api_request(
        f"/search?q={query}&type={type}&limit={limit}",
        token
    )

@app.get("/spotify/artists/{artist_id}")
async def spotify_get_artist(artist_id: str, db: Session = Depends(get_db)):
    """Obtener el expediente completo de un artista"""
    token = await _get_spotify_token(db)
    # Pedimos los datos completos directamente a la fuente
    return await _spotify_api_request(f"/artists/{artist_id}", token)
