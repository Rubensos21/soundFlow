import 'package:flutter/material.dart';
import 'playlist_result.dart';
import 'prompt_playlist.dart';
import 'services/api_client.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _communityPlaylists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommunityPlaylists();
  }

  Future<void> _loadCommunityPlaylists() async {
    try {
      final res = await _api.getCommunityPlaylists();
      setState(() {
        if (res.containsKey('playlists')) {
          _communityPlaylists = List<Map<String, dynamic>>.from(res['playlists']);
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading community playlists: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explorar',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Playlist de la comunidad
                  _sectionHeader('Playlist de la comunidad'),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const SizedBox(height: 110, child: Center(child: CircularProgressIndicator(color: Colors.white)))
                  else if (_communityPlaylists.isEmpty)
                    const SizedBox(height: 110, child: Center(child: Text('No hay playlists en la comunidad', style: TextStyle(color: Colors.white70))))
                  else
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _communityPlaylists.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final pl = _communityPlaylists[index];
                          final asset = _covers[index % _covers.length];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PlaylistResultScreen(
                                    title: pl['name'] ?? 'Playlist de la comunidad',
                                    subtitleUser: pl['author'] ?? 'Sound Flow',
                                    mood: pl['emotion'] ?? pl['method'] ?? 'Explorar',
                                    playlistId: pl['id']?.toString() ?? '',
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(asset, width: 120, height: 80, fit: BoxFit.cover),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    pl['name'] ?? 'Musica',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontFamily: 'Poppins'),
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 18),

                  // Según tus guardados (card)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('Segun tus guardados', small: true),
                        const SizedBox(height: 12),
                        ..._savedItems.map((e) => _savedTile(context, e)).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Explora por Moods
                  _sectionHeader('Explora por Moods'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 14,
                    children: _moods
                        .map((m) => _moodChip(context: context, icon: m.icon, label: m.label))
                        .toList(),
                  ),

                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ),

        // Botón flotante morado (centro inferior)
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: Center(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PromptPlaylistScreen()),
                );
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFF9C7CFE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sports_motorsports_outlined, color: Colors.white, size: 30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, {bool small = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: small ? 16 : 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.9)),
      ],
    );
  }

  static final List<String> _covers = [
    'assets/images/playlist1.png',
    'assets/images/artist1.png',
    'assets/images/artist2.png',
    'assets/images/artist3.png',
    'assets/images/artist4.png',
  ];

  static final List<_Saved> _savedItems = [
    _Saved('Heartbreak Hours', '24 Canciones | 1 h. 18 minutos', 'assets/images/artist1.png'),
    _Saved('Horas felices', '383 canciones | 22 h. 58 minutos | 1 fan', 'assets/images/artist2.png'),
    _Saved('Pensando en todo', '108 canciones | 18 h. 26 minutos | 17 fans', 'assets/images/artist3.png'),
    _Saved('Relaxing', '84 canciones | 9 h. 14 minutos | 8 fans', 'assets/images/artist4.png'),
  ];

  Widget _savedTile(BuildContext context, _Saved s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlaylistResultScreen(
                title: s.title, 
                subtitleUser: 'Tú', 
                mood: 'Guardados',
                playlistId: '',
                imageUrl: s.cover,
              ),
            ),
          );
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(s.cover, width: 44, height: 44, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.meta,
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.9)),
          ],
        ),
      ),
    );
  }

  Widget _moodChip({required BuildContext context, required String icon, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PromptPlaylistScreen()),
            );
          },
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 28)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Poppins'),
        )
      ],
    );
  }
}

class _Saved {
  final String title;
  final String meta;
  final String cover;
  _Saved(this.title, this.meta, this.cover);
}

class _Mood {
  final String icon;
  final String label;
  const _Mood(this.icon, this.label);
}

const List<_Mood> _moods = [
  _Mood('❤', 'Amor'),
  _Mood('🙂', 'Feliz'),
  _Mood('😢', 'Triste'),
  _Mood('🧠', 'Concentración'),
  _Mood('🎉', 'Party'),
];
