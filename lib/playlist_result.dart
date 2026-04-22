import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final int sourceIndex;

  const PlaylistResultScreen({
    super.key,
    required this.title,
    required this.subtitleUser,
    required this.mood,
    required this.playlistId,
    this.imageUrl,
    this.sourceIndex = 0,
  });

  @override
  State<PlaylistResultScreen> createState() => _PlaylistResultScreenState();
}

class _PlaylistResultScreenState extends State<PlaylistResultScreen> {
  bool _isLoading = true;
  
  List<dynamic> _tracks = [];
  List<dynamic> _filteredTracks = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          _filteredTracks = List.from(_tracks);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando canciones: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterTracks(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredTracks = List.from(_tracks);
      });
      return;
    }

    final lowerQuery = query.toLowerCase();

    setState(() {
      _filteredTracks = _tracks.where((trackContainer) {
        final track = trackContainer['item'] ?? trackContainer['track'] ?? trackContainer;
        
        final songName = (track['name'] ?? '').toString().toLowerCase();
        final artists = track['artists'] != null
            ? (track['artists'] as List).map((a) => a['name'].toString().toLowerCase()).join(' ')
            : '';

        return songName.contains(lowerQuery) || artists.contains(lowerQuery);
      }).toList();
    });
  }

  Future<void> _openSpotifyPlaylist() async {
    if (widget.playlistId.isEmpty) return;
    
    final urlString = 'https://open.s' + 'potify.com/playlist/${widget.playlistId}';
    final url = Uri.parse(urlString);
    
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

  void _showComingSoonMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature: Funcion proximamente'),
        backgroundColor: const Color(0xFF9C7CFE),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // NUEVO: Funcion inteligente para resaltar el texto buscado
  Widget _buildHighlightedText(String text, String query, TextStyle baseStyle) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch = lowerText.indexOf(lowerQuery, start);

    if (indexOfMatch == -1) {
      return Text(text, style: baseStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    // Estilo para el texto que coincide con la busqueda (Fondo morado, letras blancas)
    final highlightStyle = baseStyle.copyWith(
      backgroundColor: const Color(0xFF9C7CFE).withOpacity(0.5),
      color: Colors.white,
    );

    while (indexOfMatch != -1) {
      if (indexOfMatch > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfMatch), style: baseStyle));
      }
      spans.add(TextSpan(
        text: text.substring(indexOfMatch, indexOfMatch + query.length),
        style: highlightStyle,
      ));
      start = indexOfMatch + query.length;
      indexOfMatch = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) {
                              _searchController.clear();
                              _filterTracks(''); 
                            }
                          });
                        },
                        child: _roundIcon(
                          _isSearching ? Icons.close : Icons.search,
                          isActive: _isSearching,
                        ),
                      ),
                      const SizedBox(width: 14),
                      
                      GestureDetector(
                        onTap: () {
                          final link = 'https://open.s' + 'potify.com/playlist/${widget.playlistId}';
                          ShareHelper.shareText("Escucha mi playlist '${widget.title}' generada por IA en Sound Flow!\n\nLink: $link");
                        },
                        child: _roundIcon(Icons.share_outlined),
                      ),
                      const SizedBox(width: 14),
                      
                      GestureDetector(
                        onTap: () => _showComingSoonMessage('Agregar a biblioteca'),
                        child: _roundIcon(Icons.playlist_add),
                      ),
                      const Spacer(),
                      
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
                  
                  const SizedBox(height: 16),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: _isSearching ? 60.0 : 0.0,
                    child: _isSearching
                        ? TextField(
                            controller: _searchController,
                            onChanged: _filterTracks,
                            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                            decoration: InputDecoration(
                              hintText: 'Buscar en la playlist...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF9C7CFE)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  if (_isSearching) const SizedBox(height: 16) else const SizedBox(height: 8),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(color: Color(0xFF9C7CFE)),
                      ),
                    )
                  else if (_filteredTracks.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.white.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text(
                              'No se encontraron resultados',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontFamily: 'Poppins'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _filteredTracks.length,
                      itemBuilder: (context, index) {
                        final trackContainer = _filteredTracks[index];
                        final track = trackContainer['item'] ?? trackContainer['track'] ?? trackContainer;
                        
                        final artists = track['artists'] != null
                            ? (track['artists'] as List).map((a) => a['name']).join(', ')
                            : 'Artista desconocido';
                        
                        final albumImages = track['album']?['images'] as List?;
                        String? trackImg;
                        if (albumImages != null && albumImages.isNotEmpty) {
                          trackImg = albumImages.first['url'];
                        }

                        // Capturamos el texto de busqueda actual
                        final currentQuery = _searchController.text;

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
                          // Usamos la nueva funcion para resaltar el titulo
                          title: _buildHighlightedText(
                            track['name'] ?? 'Sin titulo',
                            currentQuery,
                            const TextStyle(
                              color: Colors.white, 
                              fontFamily: 'Poppins', 
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          // Usamos la nueva funcion para resaltar el artista
                          subtitle: _buildHighlightedText(
                            artists,
                            currentQuery,
                            TextStyle(
                              color: Colors.white.withOpacity(0.6), 
                              fontSize: 13, 
                              fontFamily: 'Poppins'
                            ),
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
        currentIndex: widget.sourceIndex, 
        onTap: (i) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: i)),
          );
        },
      ),
    );
  }

  Widget _roundIcon(IconData icon, {bool isActive = false}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF9C7CFE).withOpacity(0.4) : Colors.white.withOpacity(0.12),
        shape: BoxShape.circle,
        border: isActive ? Border.all(color: const Color(0xFF9C7CFE), width: 1.5) : null,
      ),
      child: Icon(
        icon, 
        color: isActive ? Colors.white : Colors.white, 
        size: 22
      ),
    );
  }
}