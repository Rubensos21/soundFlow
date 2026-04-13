import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'services/api_client.dart';
import 'utils/share_helper.dart';

class GeneratedPlaylistDetailScreen extends StatefulWidget {
  final int playlistId;

  const GeneratedPlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<GeneratedPlaylistDetailScreen> createState() => _GeneratedPlaylistDetailScreenState();
}

class _GeneratedPlaylistDetailScreenState extends State<GeneratedPlaylistDetailScreen> {
  Map<String, dynamic>? _playlist;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlaylistDetails();
  }

  Future<void> _loadPlaylistDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiClient();
      final response = await api.getGeneratedPlaylistDetail(widget.playlistId);
      
      setState(() {
        _playlist = response['playlist'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF2D1B69),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF9C7CFE)),
        ),
      );
    }

    if (_errorMessage != null || _playlist == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF2D1B69),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'Error cargando playlist',
                style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    final name = _playlist!['name'] ?? 'Sin nombre';
    final emotion = _playlist!['emotion'] ?? 'neutral';
    final prompt = _playlist!['prompt'] ?? '';
    final tracks = List<Map<String, dynamic>>.from(_playlist!['tracks'] ?? []);
    
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

    return Scaffold(
      backgroundColor: const Color(0xFF2D1B69),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(name, prompt, emotion, color, tracks.length),
            
            // Lista de canciones
            Expanded(
              child: tracks.isEmpty
                  ? _buildEmptyTracks()
                  : _buildTracksList(tracks, color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String prompt, String emotion, Color color, int tracksCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.3),
            const Color(0xFF2D1B69),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botones de acción
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  ShareHelper.shareText('Escucha mi playlist "$name" creada con IA en Sound Flow');
                },
                icon: const Icon(Icons.share, color: Colors.white),
              ),
              IconButton(
                onPressed: () {
                  // Más opciones
                },
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Icono grande de emoción
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getEmotionIcon(emotion),
              color: color,
              size: 60,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Nombre de la playlist
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Prompt usado
          if (prompt.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '"$prompt"',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  emotion.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$tracksCount canciones',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTracksList(List<Map<String, dynamic>> tracks, Color accentColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return _buildTrackItem(track, index + 1, accentColor);
      },
    );
  }

  Widget _buildTrackItem(Map<String, dynamic> track, int index, Color accentColor) {
    final title = track['title'] ?? 'Sin título';
    final artist = track['artist'] ?? 'Artista desconocido';
    final album = track['album'] ?? '';
    final imageUrl = track['image_url'];
    final duration = track['duration_ms'] ?? 0;
    
    // Convertir duración a formato mm:ss
    final minutes = (duration / 60000).floor();
    final seconds = ((duration % 60000) / 1000).floor();
    final durationStr = '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Número
            SizedBox(
              width: 30,
              child: Text(
                '$index',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            // Portada
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white.withOpacity(0.1),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.music_note, color: accentColor),
                      ),
                    )
                  : Icon(Icons.music_note, color: accentColor),
            ),
          ],
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              artist,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (album.isNotEmpty)
              Text(
                album,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              durationStr,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTracks() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay canciones en esta playlist',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontFamily: 'Poppins',
            ),
          ),
        ],
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
}

