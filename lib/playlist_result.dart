import 'package:flutter/material.dart';
import 'home.dart';
import 'widgets/app_bottom_nav.dart';
import 'utils/share_helper.dart';
import 'services/spotify_service.dart'; // Importamos el servicio

class PlaylistResultScreen extends StatefulWidget {
  final String title;
  final String subtitleUser;
  final String mood;
  final String playlistId;
  final String? imageUrl;

  const PlaylistResultScreen({
    super.key,
    required this.title,
    required this.subtitleUser,
    required this.mood,
    required this.playlistId,
    this.imageUrl,
  });

  @override
  State<PlaylistResultScreen> createState() => _PlaylistResultScreenState();
}

class _PlaylistResultScreenState extends State<PlaylistResultScreen> {
  bool _isLoading = true;
  List<dynamic> _tracks = [];

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    if (widget.playlistId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final service = SpotifyService();
      final details = await service.getPlaylistDetails(widget.playlistId);
      
      // ESPIA: Vamos a ver qué nos manda Python realmente
      print('--- DETALLES DE CANCIONES: $details');
      
      setState(() {
        // Cazador de canciones a prueba de balas:
        List<dynamic> rawTracks = [];
        
        if (details['tracks'] is Map && details['tracks']['items'] is List) {
          rawTracks = details['tracks']['items']; // Spotify original
        } else if (details['items'] is Map && details['items']['items'] is List) {
          rawTracks = details['items']['items']; // Formato de tu backend
        } else if (details['items'] is List) {
          rawTracks = details['items']; 
        } else if (details['tracks'] is List) {
          rawTracks = details['tracks'];
        }
        
        _tracks = rawTracks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando canciones: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B69),
      body: SafeArea(
        child: Stack(
          children: [
            // Botón de retroceso
            Positioned(
              left: 8,
              top: 6,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Botón de opciones
            Positioned(
              right: 8,
              top: 6,
              child: IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ),

            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PORTADA REAL DE LA PLAYLIST
                    Center(
                      child: Container(
                        height: 220,
                        width: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withOpacity(0.1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ],
                          image: widget.imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(widget.imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.imageUrl == null
                            ? const Icon(Icons.music_note, size: 80, color: Colors.white)
                            : null,
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitleUser,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'Mood: ${widget.mood}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),

                    const SizedBox(height: 16),
                    // BOTONES DE ACCIÓN
                    Row(
                      children: [
                        _roundIcon(Icons.search),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () {
                            ShareHelper.shareText('Escucha mi playlist \'${widget.title}\' en Sound Flow');
                          },
                          child: _roundIcon(Icons.share_outlined),
                        ),
                        const SizedBox(width: 14),
                        _roundIcon(Icons.playlist_add),
                        const Spacer(),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1DB954), // Verde Spotify
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // LISTA DE CANCIONES REALES
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C7CFE)))
                          : _tracks.isEmpty
                              ? Center(
                                  child: Text(
                                    'No se encontraron canciones',
                                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontFamily: 'Poppins'),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _tracks.length,
                                  itemBuilder: (context, index) {
                                    final trackContainer = _tracks[index];
                                    
                                    // Buscamos 'item' (tu backend) o 'track' (Spotify)
                                    final track = trackContainer['item'] ?? trackContainer['track'] ?? trackContainer;
                                    
                                    // Sacar los artistas
                                    final artists = track['artists'] != null
                                        ? (track['artists'] as List).map((a) => a['name']).join(', ')
                                        : 'Artista desconocido';
                                    
                                    // Sacar la imagen del álbum de esa canción
                                    final albumImages = track['album']?['images'] as List?;
                                    String? trackImg;
                                    if (albumImages != null && albumImages.isNotEmpty) {
                                      trackImg = albumImages.first['url'];
                                    }

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: trackImg != null 
                                          ? Image.network(trackImg, width: 50, height: 50, fit: BoxFit.cover)
                                          : Container(width: 50, height: 50, color: Colors.white.withOpacity(0.1), child: const Icon(Icons.music_note, color: Colors.white)),
                                      ),
                                      title: Text(
                                        track['name'] ?? 'Sin título',
                                        style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        artists,
                                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontFamily: 'Poppins'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: const Icon(Icons.more_vert, color: Colors.white54),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onTap: (i) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: i)),
          );
        },
      ),
    );
  }

  Widget _roundIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}