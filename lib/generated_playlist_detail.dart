import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // --- FUNCIONES DE BOTONES ---

  Future<void> _openInSpotify(String? uri) async {
    if (uri != null && uri.isNotEmpty) {
      final Uri spotifyUri = Uri.parse(uri);
      if (await canLaunchUrl(spotifyUri)) {
        await launchUrl(spotifyUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir Spotify. Verifica que esté instalado.')),
          );
        }
      }
    }
  }

  void _savePlaylistToSpotify() {
    // Aquí irá tu lógica futura para mandar un POST al backend y crear la playlist
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guardando en tu cuenta de Spotify...')),
    );
  }

  Future<void> _deletePlaylist() async {
    try {
      final api = ApiClient();
      // Asegúrate de tener este método en tu ApiClient: 
      await api.deleteGeneratedPlaylist(widget.playlistId);
      
      if (mounted) {
        Navigator.pop(context, true); // Regresamos y avisamos que se borró
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Pantalla de carga
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF191428), // Fondo oscuro estilo dark mode
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1DB954)), // Verde Spotify
        ),
      );
    }

    // 2. Pantalla de error
    if (_errorMessage != null || _playlist == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF191428),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'Error cargando playlist',
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954)),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Extraer datos
    final name = _playlist!['name'] ?? 'Sin nombre';
    final emotion = _playlist!['emotion'] ?? 'neutral';
    final prompt = _playlist!['prompt'] ?? '';
    final tracks = List<Map<String, dynamic>>.from(_playlist!['tracks'] ?? []);
    
    // Usar la portada de la primera canción como fondo gigante
    String coverImageUrl = 'https://via.placeholder.com/400';
    if (tracks.isNotEmpty && tracks[0]['image_url'] != null) {
      coverImageUrl = tracks[0]['image_url'];
    }

    return Scaffold(
      backgroundColor: const Color(0xFF191428),
      body: CustomScrollView(
        slivers: [
          // --- HEADER CON IMAGEN EXPANDIBLE ---
          SliverAppBar(
            expandedHeight: 340.0,
            pinned: true,
            backgroundColor: const Color(0xFF191428),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Menú inferior para eliminar
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF2A2045),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          title: const Text('Eliminar Playlist', style: TextStyle(color: Colors.redAccent, fontFamily: 'Poppins')),
                          onTap: () {
                            Navigator.pop(context);
                            _deletePlaylist();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    coverImageUrl,
                    fit: BoxFit.cover,
                  ),
                  // Degradado negro/morado oscuro sobre la imagen
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF191428).withOpacity(0.6),
                          const Color(0xFF191428),
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- INFO PRINCIPAL Y BOTONES ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white70, fontSize: 15, fontFamily: 'Poppins'),
                      children: [
                        const TextSpan(text: 'Creada por '),
                        TextSpan(
                          text: 'Yael', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mood: ${emotion.toUpperCase()}',
                    style: const TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'Poppins'),
                  ),
                  if (prompt.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Prompt: "$prompt"',
                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic, fontFamily: 'Poppins'),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Fila de botones circulares y botón Play
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildCircleButton(Icons.search, () {
                            // Acción de buscar (opcional)
                          }),
                          const SizedBox(width: 12),
                          _buildCircleButton(Icons.share_outlined, () {
                            ShareHelper.shareText('Escucha mi playlist "$name" creada en SoundFlow');
                          }),
                          const SizedBox(width: 12),
                          _buildCircleButton(Icons.playlist_add, _savePlaylistToSpotify),
                        ],
                      ),
                      FloatingActionButton(
                        backgroundColor: const Color(0xFF1DB954), // Spotify Green
                        elevation: 0,
                        onPressed: () {
                          if (tracks.isNotEmpty) {
                            _openInSpotify(tracks[0]['uri']);
                          }
                        },
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // --- LISTA DE CANCIONES (SIN NÚMEROS) ---
          tracks.isEmpty 
          ? SliverToBoxAdapter(child: _buildEmptyTracks())
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = tracks[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        track['image_url'] ?? 'https://via.placeholder.com/50',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      track['title'] ?? 'Desconocido',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      track['artist'] ?? 'Artista',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                      onPressed: () {
                        // Opciones de la canción (podrías abrir un BottomSheet aquí)
                        _openInSpotify(track['uri']);
                      },
                    ),
                    onTap: () => _openInSpotify(track['uri']),
                  );
                },
                childCount: tracks.length,
              ),
            ),
            
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Espacio al final
        ],
      ),
    );
  }

  // Widget auxiliar para los botones circulares translúcidos
  Widget _buildCircleButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildEmptyTracks() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
            Icon(Icons.music_off, size: 48, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No hay canciones en esta playlist',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Poppins'),
            ),
          ],
        ),
      ),
    );
  }
}