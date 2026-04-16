from urllib.parse import quote
from typing import Dict, List
import httpx
from loguru import logger


class EmotionDetector:
    def __init__(self) -> None:
        self.emotion_map = {
            'happy': ['upbeat', 'pop', 'dance'],
            'sad': ['acoustic', 'indie', 'ambient'],
            'angry': ['rock', 'metal', 'hip-hop'],
            'surprise': ['electronic', 'experimental'],
            'neutral': ['chill', 'jazz', 'classical']
        }

    def detect_emotion_from_image(self, _image_bytes: bytes):
        # Mock: en prod usar FER/OpenCV. Aquí devolvemos neutral
        dominant = 'neutral'
        return dominant, self.emotion_map[dominant]


class PromptProcessor:
    def analyze_prompt(self, user_prompt: str) -> Dict:
        """Analiza el prompt del usuario para extraer intención, géneros y mood"""
        text = user_prompt.lower()
        
        # Detectar emociones/mood
        emotion = 'neutral'
        if any(k in text for k in ['feliz', 'happy', 'alegre', 'party', 'fiesta', 'energía', 'energy']):
            emotion = 'happy'
        elif any(k in text for k in ['triste', 'sad', 'melancólico', 'llorar', 'depresión']):
            emotion = 'sad'
        elif any(k in text for k in ['enojado', 'angry', 'furioso', 'rage', 'metal']):
            emotion = 'angry'
        elif any(k in text for k in ['relajad', 'relax', 'chill', 'calm', 'tranquil', 'estudiar', 'focus']):
            emotion = 'calm'
        elif any(k in text for k in ['romántic', 'amor', 'love', 'romance']):
            emotion = 'romantic'
        elif any(k in text for k in ['workout', 'gym', 'ejercicio', 'deporte', 'correr']):
            emotion = 'energetic'
        
        # Detectar géneros mencionados
        genres = []
        genre_map = {
            'pop': ['pop'],
            'rock': ['rock'],
            'indie': ['indie', 'alternativ'],
            'jazz': ['jazz'],
            'classical': ['clásic', 'classical', 'orchestra'],
            'lo-fi': ['lo-fi', 'lofi'],
            'r&b': ['r&b', 'rnb', 'soul'],
            'hip-hop': ['hip-hop', 'rap', 'trap'],
            'electronic': ['electronic', 'electrónic', 'edm', 'techno', 'house'],
            'reggaeton': ['reggaeton', 'regeton', 'latino'],
            'metal': ['metal', 'heavy'],
            'country': ['country'],
            'blues': ['blues'],
            'reggae': ['reggae'],
            'folk': ['folk', 'acoustic', 'acústic']
        }
        
        for genre, keywords in genre_map.items():
            if any(k in text for k in keywords):
                genres.append(genre)
        
        # Detectar actividad/contexto
        activity = None
        if any(k in text for k in ['estudiar', 'study', 'focus', 'concentrar', 'trabajo', 'work']):
            activity = 'study'
        elif any(k in text for k in ['gym', 'workout', 'ejercicio', 'correr', 'deporte']):
            activity = 'workout'
        elif any(k in text for k in ['dormir', 'sleep', 'relax', 'descansar']):
            activity = 'sleep'
        elif any(k in text for k in ['party', 'fiesta', 'bailar', 'dance']):
            activity = 'party'
        elif any(k in text for k in ['viaje', 'carro', 'car', 'road trip']):
            activity = 'travel'
        
        return {
            'sentiment': 'POSITIVE' if emotion in ['happy', 'energetic'] else 'NEGATIVE' if emotion == 'sad' else 'NEUTRAL',
            'emotion': emotion,
            'confidence': 0.85,
            'mentioned_genres': genres if genres else self._default_genres_for_emotion(emotion),
            'activity': activity,
            'original_prompt': user_prompt
        }
    
    def _default_genres_for_emotion(self, emotion: str) -> List[str]:
        """Géneros por defecto según la emoción"""
        defaults = {
            'happy': ['pop', 'dance'],
            'sad': ['indie', 'acoustic'],
            'angry': ['rock', 'metal'],
            'calm': ['lo-fi', 'jazz', 'ambient'],
            'romantic': ['r&b', 'pop'],
            'energetic': ['electronic', 'hip-hop']
        }
        return defaults.get(emotion, ['pop', 'indie'])


class HybridRecommender:
    def __init__(self, user_id: int) -> None:
        self.user_id = user_id

    def generate_playlist_based_on_emotion(self, emotion: str, confidence: float) -> List[Dict]:
        # Mock: devolver 20 pistas sintéticas
        return self._fake_tracks(tag=emotion)

    def generate_playlist_from_prompt(self, prompt_analysis: Dict) -> List[Dict]:
        """Genera playlist basada en el análisis del prompt (versión mejorada)"""
        tag = ",".join(prompt_analysis.get('mentioned_genres', ['chill']))
        return self._fake_tracks(tag=tag)
    
    async def generate_playlist_from_spotify(
        self, 
        prompt_analysis: Dict, 
        spotify_token: str,
        limit: int = 30
    ) -> List[Dict]:
        """Genera playlist REAL buscando en Spotify"""
        try:
            genres = prompt_analysis.get('mentioned_genres', ['pop'])
            emotion = prompt_analysis.get('emotion', 'neutral')
            activity = prompt_analysis.get('activity')
            
            # Construir query de búsqueda inteligente
            search_queries = self._build_search_queries(genres, emotion, activity)
            
            tracks = []
            async with httpx.AsyncClient() as client:
                for query in search_queries[:3]:
                    try:
                        # LA SOLUCIÓN: Usamos 'params' para que httpx codifique todo
                        search_url = "https://api.spotify.com/v1/search"
                        search_params = {
                            "q": query,
                            "type": "track",
                            "limit": 20
                        }
                        headers_auth = {"Authorization": f"Bearer {spotify_token}"}
                        
                        response = await client.get(search_url, params=search_params, headers=headers_auth)
                        
                        # Esto saldrá en tu terminal de VS Code
                        print(f"--- Buscando: '{query}' | Status: {response.status_code}")
                        
                        if response.status_code == 200:
                            # ... (aquí sigue tu código igual para procesar los items)
                            data = response.json()
                            items = data.get('tracks', {}).get('items', [])
                            
                            for item in items:
                                if len(tracks) >= limit:
                                    break
                                
                                # Evitar duplicados
                                if item['id'] not in [t.get('spotify_id') for t in tracks]:
                                    tracks.append({
                                        'spotify_id': item['id'],
                                        'title': item['name'],
                                        'artist': ', '.join([a['name'] for a in item['artists']]),
                                        'album': item['album']['name'],
                                        'image_url': item['album']['images'][0]['url'] if item['album']['images'] else None,
                                        'preview_url': item.get('preview_url'),
                                        'duration_ms': item['duration_ms'],
                                        'uri': item['uri']
                                    })
                        
                        if len(tracks) >= limit:
                            break
                    
                    except Exception as e:
                        logger.error(f"Error buscando en Spotify con query '{query}': {e}")
                        continue
            
            return tracks[:limit] if tracks else self._fake_tracks("generated")
        
        except Exception as e:
            logger.error(f"Error generando playlist desde Spotify: {e}")
            return self._fake_tracks("error")
    
    def _build_search_queries(self, genres: List[str], emotion: str, activity: str = None) -> List[str]:
        """Construye frases de búsqueda simples y efectivas"""
        queries = []
        
        # Combinación de géneros y mood (Ej: "indie acoustic sad")
        base_query = f"{' '.join(genres)} {emotion}".strip()
        if base_query:
            queries.append(base_query)
        
        # Búsqueda por actividad (Ej: "workout motivation")
        if activity:
            activity_terms = {
                'study': 'focus study lofi',
                'workout': 'workout gym energy',
                'sleep': 'sleep relax ambient',
                'party': 'party dance hits',
                'travel': 'road trip chill'
            }
            if activity in activity_terms:
                queries.append(activity_terms[activity])
        
        return queries

    def _fake_tracks(self, tag: str) -> List[Dict]:
        """Tracks de respaldo si falla la búsqueda en Spotify"""
        return [
            {
                'spotify_id': f'track_{i}',
                'title': f'Track {i}',
                'artist': 'Various Artists',
                'album': 'Generated Playlist',
                'image_url': None,
                'preview_url': None,
                'duration_ms': 180000,
                'uri': f'spotify:track:fake_{i}',
                'tag': tag,
            }
            for i in range(1, 21)
        ]


