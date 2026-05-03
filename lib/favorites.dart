import 'package:flutter/material.dart';
import 'generated_playlist_detail.dart';
import 'services/api_client.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> _playlists = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiClient();
      final response = await api.getGeneratedPlaylists();
      
      setState(() {
        _playlists = List<Map<String, dynamic>>.from(response['playlists'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePlaylist(int playlistId) async {
    try {
      final api = ApiClient();
      await api.deleteGeneratedPlaylist(playlistId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playlist eliminada'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPlaylists();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error eliminando playlist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadPlaylists,
        color: const Color(0xFF9C7CFE),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Favoritos',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    _roundHeaderIcon(Icons.refresh, onTap: _loadPlaylists),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Playlists Generadas con IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _playlists.isEmpty && !_isLoading
                      ? 'Crea tu primera playlist con IA'
                      : 'Tus playlists personalizadas guardadas',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 24),
                
                // Contenido
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: Color(0xFF9C7CFE)),
                    ),
                  )
                else if (_errorMessage != null)
                  _buildError()
                else if (_playlists.isEmpty)
                  _buildEmptyState()
                else
                  _buildPlaylistsGrid(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundHeaderIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Error cargando playlists',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Error desconocido',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPlaylists,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C7CFE),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.music_note_outlined,
                size: 50,
                color: Color(0xFF9C7CFE),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No tienes playlists aún',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Genera tu primera playlist con IA desde la pantalla de inicio',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _playlists.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return _buildPlaylistCard(playlist);
      },
    );
  }

  Widget _buildPlaylistCard(Map<String, dynamic> playlist) {
    final String name = playlist['name'] ?? 'Sin nombre';
    final String emotion = playlist['emotion'] ?? 'neutral';
    final int tracksCount = playlist['tracks_count'] ?? 0;
    final int playlistId = playlist['id'] ?? 0;
    
    // Intentamos extraer la imagen de la primera canción si el backend la envía.
    // (A veces viene directo como 'image_url' en el resumen, o dentro del arreglo 'tracks')
    String? coverImageUrl = playlist['image_url'];
    if (coverImageUrl == null && playlist['tracks'] != null && (playlist['tracks'] as List).isNotEmpty) {
      coverImageUrl = playlist['tracks'][0]['image_url'];
    }
    
    // Colores basados en emoción
    final emotionColors = {
      'happy': const Color(0xFFFFC107),
      'sad': const Color(0xFF5C6BC0),
      'angry': const Color(0xFFE53935),
      'calm': const Color(0xFF66BB6A),
      'romantic': const Color(0xFFEC407A),
      'energetic': const Color(0xFFFF5722),
      'neutral': const Color(0xFF9C7CFE),
    };
    
    final color = emotionColors[emotion] ?? const Color(0xFF9C7CFE);
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GeneratedPlaylistDetailScreen(playlistId: playlistId),
          ),
        ).then((_) => _loadPlaylists());
      },
      onLongPress: () {
        _showDeleteDialog(playlistId, name);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Si no hay imagen, usamos un color oscuro de fondo por defecto
          color: const Color(0xFF2A2045),
          image: coverImageUrl != null
              ? DecorationImage(
                  image: NetworkImage(coverImageUrl),
                  fit: BoxFit.cover,
                )
              : null,
          // Solo mostramos borde si NO hay imagen de fondo
          border: coverImageUrl == null ? Border.all(color: color.withOpacity(0.3), width: 1) : null,
        ),
        child: Container(
          // CAPA MÁGICA: Degradado oscuro encima de la imagen para proteger la lectura del texto
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent, // Arriba deja ver la imagen
                const Color(0xFF191428).withOpacity(0.7),
                const Color(0xFF191428).withOpacity(0.95), // Abajo oscurece
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Si no hay imagen de fondo, seguimos mostrando el icono de la emoción arriba
              if (coverImageUrl == null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getEmotionIcon(emotion),
                    color: color,
                    size: 24,
                  ),
                ),
                
              const Spacer(), // Empuja los textos hacia abajo
              
              // Nombre de la playlist
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              // Info de cantidad de canciones
              Text(
                '$tracksCount canciones',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              // Etiqueta (Pill) del Mood
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  emotion.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'angry':
        return Icons.whatshot;
      case 'calm':
        return Icons.spa;
      case 'romantic':
        return Icons.favorite;
      case 'energetic':
        return Icons.bolt;
      default:
        return Icons.music_note;
    }
  }

  void _showDeleteDialog(int playlistId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3D2A6D),
        title: const Text(
          'Eliminar Playlist',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
        content: Text(
          '¿Seguro que quieres eliminar "$name"?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePlaylist(playlistId);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}


