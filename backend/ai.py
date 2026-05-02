"""
ai.py — Motor de IA para SoundFlow
====================================
Plan A revisado: Géneros de Artista como señal de mood
  (Spotify bloqueó /audio-features con 403 para apps nuevas desde Nov 2024)

Flujo:
  1. GET /me/tracks           → liked songs del usuario (500 max, paginado)
  2. GET /artists?ids=...     → géneros de cada artista único (batch de 50)
  3. Mapear géneros → mood    → puntuación de afinidad por canción
  4. Filtrar + ordenar        → playlist personalizada

Diseño extensible:
  - score_track_by_genres() es el único lugar que cambia si añadimos LLM.
  - Opción B: reemplazar/enriquecer ese scoring con un LLM sin tocar nada más.
"""

import random
from typing import Dict, List, Optional, Set, Tuple
import httpx
from loguru import logger


# ─────────────────────────────────────────────────────────────────────────────
# MAPA DE GÉNEROS → MOOD
# Cada género puede contribuir a uno o más moods.
# La puntuación es el número de géneros que coinciden.
# ─────────────────────────────────────────────────────────────────────────────
GENRE_MOOD_MAP: Dict[str, List[str]] = {
    # ── Positivos / Feliz
    "pop":              ["happy", "energetic"],
    "dance pop":        ["happy", "energetic", "excited"],
    "electropop":       ["happy", "energetic"],
    "pop rock":         ["happy"],
    "indie pop":        ["happy", "calm"],
    "funk":             ["happy", "energetic"],
    "disco":            ["happy", "energetic", "excited"],
    "reggaeton":        ["happy", "energetic"],
    "latin":            ["happy", "romantic"],
    "latin pop":        ["happy", "romantic"],
    "k-pop":            ["happy", "excited"],
    "j-pop":            ["happy"],
    "tropical":         ["happy"],
    "summer":           ["happy"],
    "party":            ["happy", "excited"],

    # ── Energético / Workout
    "hip hop":          ["energetic", "workout"],
    "rap":              ["energetic", "workout"],
    "trap":             ["energetic", "workout"],
    "edm":              ["energetic", "workout", "excited"],
    "electronic":       ["energetic", "excited"],
    "house":            ["energetic", "excited"],
    "techno":           ["energetic"],
    "drum and bass":    ["energetic", "workout"],
    "dubstep":          ["energetic", "excited"],
    "trance":           ["energetic", "excited"],
    "hardstyle":        ["workout"],
    "speed metal":      ["angry", "workout"],
    "workout":          ["workout"],
    "fitness":          ["workout"],

    # ── Tranquilo / Chill
    "lo-fi":            ["calm", "focus"],
    "lo fi":            ["calm", "focus"],
    "ambient":          ["calm", "focus"],
    "new age":          ["calm"],
    "chillout":         ["calm"],
    "chill":            ["calm"],
    "classical":        ["calm", "focus"],
    "jazz":             ["calm", "romantic"],
    "smooth jazz":      ["calm", "romantic"],
    "bossa nova":       ["calm", "romantic"],
    "acoustic":         ["calm", "sad"],
    "folk":             ["calm", "sad"],
    "singer-songwriter":["calm", "sad", "romantic"],
    "meditation":       ["calm", "focus"],
    "sleep":            ["calm"],
    "piano":            ["calm", "sad", "romantic"],

    # ── Triste / Melancólico
    "blues":            ["sad"],
    "soul":             ["sad", "romantic"],
    "emo":              ["sad"],
    "sad":              ["sad"],
    "slowcore":         ["sad"],
    "dreampop":         ["sad", "calm"],
    "indie":            ["sad", "calm"],
    "alternative":      ["sad", "angry"],
    "shoegaze":         ["sad", "calm"],
    "post-rock":        ["sad", "calm"],
    "grunge":           ["sad", "angry"],
    "emo rap":          ["sad"],
    "dark":             ["sad", "angry"],
    "gothic":           ["sad", "angry"],

    # ── Intenso / Enojado
    "metal":            ["angry"],
    "heavy metal":      ["angry"],
    "rock":             ["angry", "energetic"],
    "hard rock":        ["angry", "energetic"],
    "punk":             ["angry"],
    "hardcore":         ["angry"],
    "industrial":       ["angry"],
    "thrash metal":     ["angry"],
    "death metal":      ["angry"],
    "black metal":      ["angry"],
    "metalcore":        ["angry"],
    "post-hardcore":    ["angry"],
    "screamo":          ["angry"],

    # ── Romántico
    "r&b":              ["romantic", "sad"],
    "neo soul":         ["romantic"],
    "soft rock":        ["romantic", "calm"],
    "love songs":       ["romantic"],
    "ballad":           ["romantic", "sad"],
    "bolero":           ["romantic"],
    "bachata":          ["romantic"],
    "salsa":            ["romantic", "happy"],

    # ── Focus / Estudio
    "study":            ["focus"],
    "concentration":    ["focus"],
    "instrumental":     ["focus", "calm"],
    "post-bop":         ["focus"],
    "downtempo":        ["focus", "calm"],
    "trip hop":         ["focus", "sad"],
    "nu jazz":          ["focus", "calm"],
}

# Alias: emociones del detector facial → nombres de mood
EMOTION_ALIAS: Dict[str, str] = {
    "happy":     "happy",
    "excited":   "excited",
    "calm":      "calm",
    "sad":       "sad",
    "fearful":   "sad",
    "angry":     "angry",
    "disgust":   "angry",
    "surprised": "excited",
    "neutral":   "neutral",
}

# Nombres creativos de playlist por mood
MOOD_PLAYLIST_NAMES: Dict[str, List[str]] = {
    "happy":    ["Good Vibes Only ✨", "Feel-Good Mix 😊", "Happiness Playlist 🌟"],
    "excited":  ["Hype Mode 🔥", "Energy Boost ⚡", "Get Pumped! 🎉"],
    "calm":     ["Chill Zone 🌊", "Relax & Breathe 🌿", "Peaceful Sounds 🕊️"],
    "sad":      ["Rainy Day Mix 🌧️", "Melancholic Mood 💙", "Heartfelt Songs 🥺"],
    "angry":    ["Release It 💥", "Intense Mode 🤘", "Raw Energy Mix"],
    "romantic": ["Love Songs 💕", "Para Ti ❤️", "Romantic Vibes 🌹"],
    "energetic":["Power Hour ⚡", "Non-Stop Energy 🔋", "Go Mode 🚀"],
    "workout":  ["Gym Beast 💪", "Workout Fuel 🏋️", "Push The Limit 🔥"],
    "focus":    ["Deep Focus 🎯", "Study Mode 📚", "Flow State 🧠"],
    "neutral":  ["Daily Mix 🎵", "Mood Board 🎶", "Tu Soundtrack 🎼"],
}

# Mood "neutral" acepta cualquier canción
_ALL_MOODS: Set[str] = set(MOOD_PLAYLIST_NAMES.keys())


# ─────────────────────────────────────────────────────────────────────────────
# DETECTOR DE EMOCIÓN FACIAL (stub, listo para DeepFace)
# ─────────────────────────────────────────────────────────────────────────────
class EmotionDetector:
    def detect_emotion_from_image(self, image_bytes: bytes) -> Tuple[str, List[str]]:
        """
        Detecta emoción en imagen.
        Stub actual → 'neutral'. Para producción, descomentar el bloque DeepFace.
        """
        # ── Producción: DeepFace ──────────────────────────────────────────
        # try:
        #     from deepface import DeepFace
        #     import tempfile, os
        #     with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as f:
        #         f.write(image_bytes); tmp = f.name
        #     result = DeepFace.analyze(img_path=tmp, actions=['emotion'], enforce_detection=False)
        #     os.unlink(tmp)
        #     return result[0]['dominant_emotion'], []
        # except Exception as e:
        #     logger.warning(f"DeepFace falló: {e}")
        # ─────────────────────────────────────────────────────────────────
        return "neutral", []


# ─────────────────────────────────────────────────────────────────────────────
# ANALIZADOR DE PROMPTS
# ─────────────────────────────────────────────────────────────────────────────
class PromptProcessor:
    def analyze_prompt(self, user_prompt: str) -> Dict:
        text = user_prompt.lower()
        mood = "neutral"
        mood_keywords = {
            "happy":    ["feliz", "happy", "alegre", "contento", "bien", "genial", "fiesta", "party", "celebr"],
            "excited":  ["emocionado", "excited", "hype", "animado", "entusiasm"],
            "calm":     ["relajad", "relax", "chill", "calm", "tranquil", "paz", "sereno"],
            "sad":      ["triste", "sad", "melancól", "nostálgic", "llorar", "deprim", "extraño", "soledad"],
            "angry":    ["enojad", "angry", "furioso", "rage", "frustr"],
            "romantic": ["romántic", "amor", "love", "romance", "enamorad", "corazón"],
            "energetic":["energía", "energy", "motivad", "activad", "dinámico"],
            "workout":  ["gym", "workout", "ejercicio", "deporte", "correr", "entrena", "pesas"],
            "focus":    ["estudiar", "study", "focus", "trabajo", "work", "concentr", "leer"],
        }
        for m, keywords in mood_keywords.items():
            if any(k in text for k in keywords):
                mood = m
                break

        genres: List[str] = []
        genre_map = {
            "pop":       ["pop"], "rock": ["rock"], "indie": ["indie", "alternativ"],
            "jazz":      ["jazz"], "classical": ["clásic", "classical"],
            "lo-fi":     ["lo-fi", "lofi"], "r&b": ["r&b", "rnb", "soul"],
            "hip-hop":   ["hip-hop", "rap", "trap"],
            "electronic":["electronic", "electrónic", "edm", "techno", "house"],
            "reggaeton": ["reggaeton", "regeton", "latino"],
            "metal":     ["metal", "heavy"], "folk": ["folk", "acoustic"],
        }
        for genre, kws in genre_map.items():
            if any(k in text for k in kws):
                genres.append(genre)

        activity: Optional[str] = None
        for act, kws in {
            "study":   ["estudiar", "study", "focus", "concentr"],
            "workout": ["gym", "workout", "ejercicio", "correr"],
            "sleep":   ["dormir", "sleep", "relax", "descansar"],
            "party":   ["party", "fiesta", "bailar"],
        }.items():
            if any(k in text for k in kws):
                activity = act
                break

        return {
            "mood": mood, "emotion": mood,
            "genres": genres, "activity": activity,
            "original_prompt": user_prompt,
            "mentioned_genres": genres,
        }


# ─────────────────────────────────────────────────────────────────────────────
# MOTOR DE RECOMENDACIÓN POR GÉNEROS DE ARTISTA
# ─────────────────────────────────────────────────────────────────────────────
class MoodRecommender:
    """
    Genera playlists desde liked songs usando géneros de artista como señal de mood.
    Diseñado para ser extendido con LLM (Opción B) sin cambiar la interfaz.
    """
    SPOTIFY_API  = "https://api.spotify.com/v1"
    LIKED_PAGE   = 50    # max por paginación de /me/tracks
    ARTIST_BATCH = 50    # max por request de /artists?ids=...

    def __init__(self, spotify_token: str) -> None:
        self.token   = spotify_token
        self._hdrs   = {"Authorization": f"Bearer {spotify_token}"}

    # ── 1. Liked Songs ────────────────────────────────────────────────────
    async def fetch_liked_songs(self, max_tracks: int = 500) -> List[Dict]:
        tracks: List[Dict] = []
        params = {"limit": self.LIKED_PAGE, "offset": 0}

        async with httpx.AsyncClient(timeout=20.0) as client:
            while len(tracks) < max_tracks:
                resp = await client.get(
                    f"{self.SPOTIFY_API}/me/tracks",
                    headers=self._hdrs, params=params,
                )
                if resp.status_code == 401:
                    raise PermissionError("Token expirado al leer liked songs")
                if resp.status_code != 200:
                    logger.warning(f"Liked songs [{resp.status_code}]")
                    break
                data  = resp.json()
                items = data.get("items", [])
                if not items:
                    break
                for item in items:
                    track = item.get("track")
                    if not track or not track.get("id"):
                        continue
                    # Guardar IDs de artistas para enriquecer después
                    artist_ids = [a["id"] for a in track["artists"] if a.get("id")]
                    tracks.append({
                        "spotify_id":  track["id"],
                        "title":       track["name"],
                        "artist":      ", ".join(a["name"] for a in track["artists"]),
                        "album":       track["album"]["name"],
                        "image_url":   track["album"]["images"][0]["url"] if track["album"]["images"] else None,
                        "preview_url": track.get("preview_url"),
                        "duration_ms": track["duration_ms"],
                        "uri":         track["uri"],
                        "popularity":  track.get("popularity", 0),
                        "artist_ids":  artist_ids,
                    })
                    if len(tracks) >= max_tracks:
                        break
                if not data.get("next") or len(tracks) >= max_tracks:
                    break
                params["offset"] += self.LIKED_PAGE

        logger.info(f"Liked songs obtenidas: {len(tracks)}")
        return tracks

    # ── 2. Géneros de Artistas (batch) ───────────────────────────────────
    async def fetch_artist_genres(self, artist_ids: List[str]) -> Dict[str, List[str]]:
        """Devuelve {artist_id: [genres]} para todos los IDs dados."""
        genres_map: Dict[str, List[str]] = {}
        unique_ids = list(dict.fromkeys(artist_ids))  # deduplica manteniendo orden

        async with httpx.AsyncClient(timeout=20.0) as client:
            for i in range(0, len(unique_ids), self.ARTIST_BATCH):
                batch = unique_ids[i: i + self.ARTIST_BATCH]
                resp  = await client.get(
                    f"{self.SPOTIFY_API}/artists",
                    headers=self._hdrs,
                    params={"ids": ",".join(batch)},
                )
                if resp.status_code != 200:
                    logger.warning(f"Artists [{resp.status_code}]: {resp.text[:150]}")
                    continue
                for artist in resp.json().get("artists") or []:
                    if artist and artist.get("id"):
                        genres_map[artist["id"]] = [g.lower() for g in artist.get("genres", [])]

        logger.info(f"Géneros obtenidos para {len(genres_map)} artistas únicos")
        return genres_map

    # ── 3. Puntuar canción según mood ─────────────────────────────────────
    @staticmethod
    def score_track(track: Dict, genres_map: Dict[str, List[str]], mood: str) -> float:
        """
        Devuelve una puntuación (0.0–N) basada en cuántos géneros del artista
        coinciden con el mood objetivo.

        mood='neutral' → todas las canciones reciben 1.0 (sin filtro).

        [Extensión futura — Opción B]:
            Añadir aquí una llamada a LLM para re-puntuar las candidatas.
        """
        if mood == "neutral":
            return 1.0 + (track.get("popularity", 0) / 200.0)

        score = 0.0
        for artist_id in track.get("artist_ids", []):
            for genre in genres_map.get(artist_id, []):
                moods_for_genre = GENRE_MOOD_MAP.get(genre, [])
                if mood in moods_for_genre:
                    score += 1.0
                # Bonus por género exacto (variantes)
                for g_key in GENRE_MOOD_MAP:
                    if g_key in genre and mood in GENRE_MOOD_MAP[g_key]:
                        score += 0.3
        # Bonus de popularidad (desempate suave)
        score += track.get("popularity", 0) / 500.0
        return score

    # ── 4. Punto de entrada principal ────────────────────────────────────
    async def generate_playlist(
        self,
        mood: str,
        playlist_size: int = 25,
        max_liked: int = 500,
    ) -> Tuple[List[Dict], int]:
        """
        Genera una playlist desde liked songs filtradas por mood.
        Retorna (tracks_seleccionadas, total_liked_analizadas).
        """
        mood = EMOTION_ALIAS.get(mood, mood)
        if mood not in _ALL_MOODS:
            mood = "neutral"

        # 1. Liked songs
        liked = await self.fetch_liked_songs(max_liked)
        if not liked:
            logger.warning("Sin liked songs — devolviendo lista vacía")
            return [], 0

        # 2. Géneros de artistas únicos
        all_artist_ids = list({aid for t in liked for aid in t.get("artist_ids", [])})
        genres_map     = await self.fetch_artist_genres(all_artist_ids)

        # 3. Puntuar y filtrar
        scored: List[Tuple[float, Dict]] = []
        for track in liked:
            s = self.score_track(track, genres_map, mood)
            if s > 0:
                scored.append((s, track))

        logger.info(f"Mood '{mood}': {len(scored)} candidatas de {len(liked)} liked songs")

        # 4. Si quedan muy pocas, ampliar: aceptar cualquier canción popular
        if len(scored) < playlist_size:
            logger.warning(f"Pocas candidatas ({len(scored)}) — ampliando con popularidad")
            for track in liked:
                if not any(t[1]["spotify_id"] == track["spotify_id"] for t in scored):
                    scored.append((track.get("popularity", 0) / 100.0, track))

        # 5. Ordenar por puntuación desc
        scored.sort(key=lambda x: x[0], reverse=True)

        # 6. Tomar el top pool con algo de variedad aleatoria
        top_pool = [t for _, t in scored[:max(playlist_size * 3, 60)]]
        selected = random.sample(top_pool, min(playlist_size, len(top_pool)))

        # Limpiar campo interno antes de devolver
        for t in selected:
            t.pop("artist_ids", None)
            t.pop("_feat", None)

        return selected, len(liked)

    # ── Nombre de playlist ────────────────────────────────────────────────
    @staticmethod
    def playlist_name_for_mood(mood: str, prompt: Optional[str] = None) -> str:
        if prompt and len(prompt) <= 45:
            return prompt.title()
        names = MOOD_PLAYLIST_NAMES.get(
            EMOTION_ALIAS.get(mood, mood),
            MOOD_PLAYLIST_NAMES["neutral"],
        )
        return random.choice(names)


# ─────────────────────────────────────────────────────────────────────────────
# WRAPPERS DE COMPATIBILIDAD (mantienen la firma usada en app.py anterior)
# ─────────────────────────────────────────────────────────────────────────────
class HybridRecommender:
    def __init__(self, user_id: int) -> None:
        self.user_id = user_id

    def generate_playlist_based_on_emotion(self, emotion: str, confidence: float) -> List[Dict]:
        return self._fake_tracks(emotion)

    def generate_playlist_from_prompt(self, analysis: Dict) -> List[Dict]:
        return self._fake_tracks(analysis.get("mood", "neutral"))

    async def generate_playlist_from_spotify(
        self, analysis: Dict, token: str, limit: int = 30
    ) -> List[Dict]:
        mood  = analysis.get("mood") or analysis.get("emotion", "neutral")
        rec   = MoodRecommender(token)
        tracks, _ = await rec.generate_playlist(mood, playlist_size=limit)
        return tracks if tracks else self._fake_tracks(mood)

    def _fake_tracks(self, tag: str) -> List[Dict]:
        return [
            {
                "spotify_id":  f"track_{i}",
                "title":       f"Track {i}",
                "artist":      "Various Artists",
                "album":       "Generated Playlist",
                "image_url":   None,
                "preview_url": None,
                "duration_ms": 180000,
                "uri":         f"spotify:track:fake_{i}",
            }
            for i in range(1, 21)
        ]
