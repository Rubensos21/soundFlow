import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // IMPORTANTE: Para abrir Spotify
import 'home.dart';
import 'widgets/app_bottom_nav.dart';
import 'utils/share_helper.dart';
import 'services/spotify_service.dart';

class PlaylistResultScreen extends StatefulWidget {
  final String title;
  final String subtitleUser;
  final String mood;
  final String playlistId;
  final String? imageUrl;
  final int sourceIndex; // <-- NUEVO: Para saber qué ícono iluminar en la barra

  const PlaylistResultScreen({
    super.key,
    required this.title,
    required this.subtitleUser,
    required this.mood,
    required this.playlistId,
    this.imageUrl,
    this.sourceIndex = 0, // Por defecto iluminará el 0 (Mi música)
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
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    try {
      final service = SpotifyService();
      final details = await service.getPlaylistDetails(widget.playlistId);
      
      if (mounted) {
        setState(() {
          List<dynamic> rawTracks = [];
          
          if (details['tracks'] is Map && details['tracks']['items'] is List) {
            rawTracks = details['tracks']['items'];
          } else if (details['items'] is Map && details['items']['items'] is List) {
            rawTracks = details['items']['items'];
          } else if (details['items'] is List) {
            rawTracks = details['items']; 
          } else if (details['tracks'] is List) {
            rawTracks = details['tracks'];
          }
          
          _tracks = rawTracks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando canciones: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Función para abrir Spotify
  Future<void> _openSpotifyPlaylist() async {
    if (widget.playlistId.isEmpty) return;
    
    final url = Uri.parse('https://open.spotify.com/playlist/${widget.playlistId}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Spotify')),
        );
      }
    }
  }

  // Función para mostrar mensajes temporales
  void _showComingSoonMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature: Función próximamente'),
        backgroundColor: const Color(0xFF9C7CFE),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B69),
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showComingSoonMessage('Opciones'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero Image (Portada + Textos) ────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 380,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.imageUrl != null)
                    Image.network(widget.imageUrl!, fit: BoxFit.cover)
                  else
                    Container(
                      color: Colors.white.withOpacity(0.05),
                      child: const Icon(Icons.music_note, size: 80, color: Colors.white24),
                    ),
                  
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF2D1B69).withOpacity(0.6),
                          const Color(0xFF2D1B69),
                        ],
                        stops: const [0.3, 0.75, 1.0],
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitleUser,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Mood: ${widget.mood}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Contenido inferior (Botones y Lista) ────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Botones de acción funcionales
                  Row(
                    children: [
                      // Botón Buscar
                      GestureDetector(
                        onTap: () => _showComingSoonMessage('Buscar en playlist'),
                        child: _roundIcon(Icons.search),
                      ),
                      const SizedBox(width: 14),
                      
                      // Botón Compartir
                      GestureDetector(
                        onTap: () {
                          ShareHelper.shareText('🎵 Escucha mi playlist \'${widget.title}\' generada por IA en Sound Flow!\n\nLink: https://open.spotify.com/playlist/${widget.playlistId}');
                        },
                        child: _roundIcon(Icons.share_outlined),
                      ),
                      const SizedBox(width: 14),
                      
                      // Botón Agregar
                      GestureDetector(
                        onTap: () => _showComingSoonMessage('Agregar a biblioteca'),
                        child: _roundIcon(Icons.playlist_add),
                      ),
                      const Spacer(),
                      
                      // Botón PLAY de Spotify
                      GestureDetector(
                        onTap: _openSpotifyPlaylist,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1DB954),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Lista de canciones
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(color: Color(0xFF9C7CFE)),
                      ),
                    )
                  else if (_tracks.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Text(
                          'No se encontraron canciones',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontFamily: 'Poppins'),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _tracks.length,
                      itemBuilder: (context, index) {
                        final trackContainer = _tracks[index];
                        final track = trackContainer['item'] ?? trackContainer['track'] ?? trackContainer;
                        
                        final artists = track['artists'] != null
                            ? (track['artists'] as List).map((a) => a['name']).join(', ')
                            : 'Artista desconocido';
                        
                        final albumImages = track['album']?['images'] as List?;
                        String? trackImg;
                        if (albumImages != null && albumImages.isNotEmpty) {
                          trackImg = albumImages.first['url'];
                        }

                        // Al tocar la canción, también la abrimos en Spotify
                        return ListTile(
                          onTap: () {
                            final spotifyUrl = track['external_urls']?['spotify'];
                            if (spotifyUrl != null) {
                              launchUrl(Uri.parse(spotifyUrl), mode: LaunchMode.externalApplication);
                            }
                          },
                          contentPadding: const EdgeInsets.symmetric(vertical: 6),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: trackImg != null 
                              ? Image.network(trackImg, width: 50, height: 50, fit: BoxFit.cover)
                              : Container(
                                  width: 50, height: 50, 
                                  color: Colors.white.withOpacity(0.1), 
                                  child: const Icon(Icons.music_note, color: Colors.white54)
                                ),
                          ),
                          title: Text(
                            track['name'] ?? 'Sin título',
                            style: const TextStyle(
                              color: Colors.white, 
                              fontFamily: 'Poppins', 
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            artists,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6), 
                              fontSize: 13, 
                              fontFamily: 'Poppins'
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.more_vert, color: Colors.white54),
                        );
                      },
                    ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        // NUEVO: Usa la variable para iluminar el ícono correcto
        currentIndex: widget.sourceIndex, 
        onTap: (i) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: i)),
          );
        },
      ),
    );
  }

  Widget _roundIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}