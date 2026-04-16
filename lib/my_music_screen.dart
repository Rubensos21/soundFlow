import 'playlist_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/app_bottom_nav.dart';
import 'home.dart';
import 'services/api_client.dart';
import 'services/apple_music_service.dart';
import 'services/deezer_service.dart';
import 'services/spotify_service.dart';
import 'services/streaming_service.dart';

class MyMusicScreen extends StatefulWidget {
  const MyMusicScreen({super.key});

  @override
  State<MyMusicScreen> createState() => _MyMusicScreenState();
}

class _MyMusicScreenState extends State<MyMusicScreen>
    with SingleTickerProviderStateMixin {
  static const Map<String, String> _platformLogos = {
    'spotify': 'assets/svg/spotify.svg',
    'deezer': 'assets/svg/deezer.svg',
    'apple': 'assets/svg/applemusic.svg',
  };

  static const List<String> _platformOrder = ['spotify', 'deezer', 'apple'];

  late TabController _tabController;
  late final Map<String, StreamingService> _streamingServices;

  bool _isLoading = true;
  bool _hasAnyPlatformConnected = false;

  Map<String, bool> _connectedPlatforms = {};
  Map<String, Map<String, dynamic>> _profilesByPlatform = {};
  Map<String, List<Map<String, dynamic>>> _playlistsByPlatform = {};
  Map<String, List<Map<String, dynamic>>> _favoritesByPlatform = {};
  Map<String, List<Map<String, dynamic>>> _recentByPlatform = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _streamingServices = {
      'spotify': SpotifyService(),
      'deezer': DeezerService(),
      'apple': AppleMusicService(),
    };
    _loadStreamingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStreamingData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final Map<String, bool> connected = {};
    final Map<String, Map<String, dynamic>> profiles = {};
    final Map<String, List<Map<String, dynamic>>> playlists = {};
    final Map<String, List<Map<String, dynamic>>> favorites = {};
    final Map<String, List<Map<String, dynamic>>> recent = {};
    final List<String> warnings = [];

    for (final entry in _streamingServices.entries) {
      final platform = entry.key;
      final service = entry.value;

      try {
        final hasConnection = await service.hasConnection();
        connected[platform] = hasConnection;

        if (!hasConnection) {
          continue;
        }

        profiles[platform] = await service.getUserProfile();
        playlists[platform] = await service.getUserPlaylists();
        favorites[platform] = await service.getUserTopTracks();
        recent[platform] = await service.getRecentlyPlayed();
      } catch (e) {
        warnings.add(
          'No se pudo cargar ${StreamingService.platformDisplayName(platform)}: $e',
        );
      }
    }

    if (!mounted) return;

    setState(() {
      _connectedPlatforms = connected;
      _profilesByPlatform = profiles;
      _playlistsByPlatform = playlists;
      _favoritesByPlatform = favorites;
      _recentByPlatform = recent;
      _hasAnyPlatformConnected = connected.values.any((value) => value);
      _isLoading = false;
      _errorMessage = warnings.isNotEmpty ? warnings.join('\n') : null;
    });
  }

  Future<void> _connectPlatform(String platform) async {
    try {
      final api = ApiClient();
      final authUrl = api.getAuthUrl(platform);
      final uri = Uri.parse(authUrl);

      if (!await canLaunchUrl(uri)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el enlace de autenticación'),
            ),
          );
        }
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF3D2A6D),
          title: Text(
            'Vinculando ${StreamingService.platformDisplayName(platform)}...',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF9C7CFE)),
              const SizedBox(height: 16),
              Text(
                'El navegador se abrió. Autoriza la conexión, luego cierra la ventana y presiona "Listo" para continuar.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _loadStreamingData();
                if (!mounted) return;

                final isLinked = _connectedPlatforms[platform] == true;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isLinked
                          ? '¡${StreamingService.platformDisplayName(platform)} vinculada exitosamente!'
                          : 'No se detectó la vinculación. Intenta de nuevo.',
                    ),
                    backgroundColor: isLinked ? Colors.green : Colors.orange,
                  ),
                );
              },
              child: const Text(
                'Listo',
                style: TextStyle(
                  color: Color(0xFF9C7CFE),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error vinculando cuenta: $e')),
        );
      }
    }
  }

  MapEntry<String, Map<String, dynamic>>? get _primaryProfileEntry {
    for (final platform in _platformOrder) {
      final profile = _profilesByPlatform[platform];
      if (profile != null) {
        return MapEntry(platform, profile);
      }
    }
    return null;
  }

  String _platformDisplayName(String platform) {
    return StreamingService.platformDisplayName(platform);
  }

  List<Map<String, dynamic>> _aggregateByPlatform(
    Map<String, List<Map<String, dynamic>>> source,
  ) {
    final List<Map<String, dynamic>> result = [];
    for (final platform in _platformOrder) {
      final items = source[platform];
      if (items == null || items.isEmpty) continue;
      for (final item in items) {
        result.add({'platform': platform, 'data': item});
      }
    }
    return result;
  }

  Widget _buildPlatformChip(String platform) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: SvgPicture.asset(
              _platformLogos[platform] ?? _platformLogos['spotify']!,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _platformDisplayName(platform),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String? _formatPlayedAt(Map<String, dynamic> track) {
    final playedAt = track['played_at'];
    if (playedAt is! String) return null;
    try {
      final dt = DateTime.parse(playedAt).toLocal();
      final twoDigits = (int value) => value.toString().padLeft(2, '0');
      return 'Reproducida el ${twoDigits(dt.day)}/${twoDigits(dt.month)} a las ${twoDigits(dt.hour)}:${twoDigits(dt.minute)}';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B69),
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : !_hasAnyPlatformConnected
                ? _buildConnectPlatforms()
                : _buildContent(),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (i) {
          if (i != 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: i)),
            );
          }
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF9C7CFE)),
          SizedBox(height: 16),
          Text(
            'Cargando tu música...',
            style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectPlatforms() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/svg/spotify.svg',
                  width: 60,
                  height: 60,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Conecta tus plataformas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Vincula Spotify, Deezer o Apple Music para ver tus playlists, canciones favoritas y recientes en un solo lugar.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Column(
              children: _platformOrder
                  .map(
                    (platform) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ElevatedButton.icon(
                        onPressed: () => _connectPlatform(platform),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: platform == 'spotify'
                              ? const Color(0xFF1DB954)
                              : platform == 'deezer'
                                  ? const Color(0xFFEF5466)
                                  : const Color(0xFFFA2D48),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        icon: SvgPicture.asset(
                          _platformLogos[platform]!,
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        label: Text(
                          'Conectar con ${_platformDisplayName(platform)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        _buildTabs(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPlaylistsTab(),
              _buildFavoritesTab(),
              _buildRecentTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final profileEntry = _primaryProfileEntry;
    final profile = profileEntry?.value;

    final images = profile?['images'] as List?;
    String? imageUrl;
    if (images != null && images.isNotEmpty) {
      final first = images.first as Map<String, dynamic>;
      imageUrl = first['url'] as String?;
    }

    final displayName = profile?['display_name'] ?? 'Usuario de Soundflow';

    final connectedChips = _connectedPlatforms.entries
        .where((entry) => entry.value)
        .map((entry) => _buildPlatformChip(entry.key))
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF1DB954),
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null
                ? const Icon(Icons.person, color: Colors.white, size: 30)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mi Música',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  displayName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (connectedChips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: connectedChips,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: _loadStreamingData,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF9C7CFE),
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Playlists'),
          Tab(text: 'Favoritos'),
          Tab(text: 'Recientes'),
        ],
      ),
    );
  }

  Widget _buildPlaylistsTab() {
    final aggregated = _aggregateByPlatform(_playlistsByPlatform);
    if (aggregated.isEmpty) {
      return _buildEmptyState('No hay playlists disponibles todavía');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: aggregated.length,
      itemBuilder: (context, index) {
        final entry = aggregated[index];
        final platform = entry['platform'] as String;
        final playlist = entry['data'] as Map<String, dynamic>;
        return _buildPlaylistItem(platform, playlist);
      },
    );
  }

  Widget _buildPlaylistItem(String platform, Map<String, dynamic> playlist) {
    // AGREGA ESTA LÍNEA AQUÍ:
    print('--- DATOS DE PLAYLIST: $playlist');
    final images = playlist['images'] as List?;
    String? imageUrl;
    if (images != null && images.isNotEmpty) {
      final first = images.first as Map<String, dynamic>;
      imageUrl = first['url'] as String?;
    }

    // --- CONTADOR CORREGIDO BASADO EN TUS LOGS ---
    int trackCount = 0;
    try {
      // Buscamos 'items' (como lo envía tu backend) o 'tracks' por si acaso
      var t = playlist['items'] ?? playlist['tracks']; 
      if (t is Map) trackCount = t['total'] ?? 0;
      else if (t is int) trackCount = t;
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withOpacity(0.1),
          ),
          child: imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(imageUrl, fit: BoxFit.cover),
                )
              : const Icon(Icons.music_note, color: Colors.white),
        ),
        title: Text(
          playlist['name'] ?? 'Sin nombre',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$trackCount canciones',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            _buildPlatformChip(platform),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
        // --- CORRECCIÓN DE LA NAVEGACIÓN ---
          // --- NUEVA NAVEGACIÓN ---
          onTap: () {
            final ownerName = playlist['owner'] != null 
                ? playlist['owner']['display_name'] 
                : 'Spotify';

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PlaylistResultScreen(
                  title: playlist['name'] ?? 'Sin nombre',
                  subtitleUser: 'Creada por $ownerName',
                  mood: 'Tu música',
                  playlistId: playlist['id'] ?? '', // Le pasamos el ID real
                  imageUrl: imageUrl,               // Le pasamos la portada real
                ),
              ),
            );
          },
      ),
    );
  }

  Widget _buildFavoritesTab() {
    final aggregated = _aggregateByPlatform(_favoritesByPlatform);
    if (aggregated.isEmpty) {
      return _buildEmptyState('No hay canciones favoritas aún');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: aggregated.length,
      itemBuilder: (context, index) {
        final entry = aggregated[index];
        final platform = entry['platform'] as String;
        final track = entry['data'] as Map<String, dynamic>;
        return _buildTrackItem(platform, track, index + 1);
      },
    );
  }

  Widget _buildTrackItem(
    String platform,
    Map<String, dynamic> track,
    int index,
  ) {
    final album = track['album'] as Map<String, dynamic>?;
    final images = album?['images'] as List?;
    String? imageUrl;
    if (images != null && images.isNotEmpty) {
      final first = images.first as Map<String, dynamic>;
      imageUrl = first['url'] as String?;
    }

    final artists = track['artists'] != null
        ? (track['artists'] as List)
            .map((artist) => (artist as Map)['name'])
            .join(', ')
        : 'Artista desconocido';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '$index',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
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
                      child: Image.network(imageUrl, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.music_note, color: Colors.white),
            ),
          ],
        ),
        title: Text(
          track['name'] ?? 'Sin título',
          style: const TextStyle(
            color: Colors.white,
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
              artists,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            _buildPlatformChip(platform),
          ],
        ),
        trailing: const Icon(Icons.more_vert, color: Colors.white),
      ),
    );
  }

  Widget _buildRecentTab() {
    final aggregated = _aggregateByPlatform(_recentByPlatform);
    if (aggregated.isEmpty) {
      return _buildEmptyState('Conecta una plataforma para ver tus recientes');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: aggregated.length,
      itemBuilder: (context, index) {
        final entry = aggregated[index];
        final platform = entry['platform'] as String;
        final track = entry['data'] as Map<String, dynamic>;
        return _buildRecentItem(platform, track, index + 1);
      },
    );
  }

  Widget _buildRecentItem(
    String platform,
    Map<String, dynamic> track,
    int index,
  ) {
    final album = track['album'] as Map<String, dynamic>?;
    final images = album?['images'] as List?;
    String? imageUrl;
    if (images != null && images.isNotEmpty) {
      final first = images.first as Map<String, dynamic>;
      imageUrl = first['url'] as String?;
    }

    final artists = track['artists'] != null
        ? (track['artists'] as List)
            .map((artist) => (artist as Map)['name'])
            .join(', ')
        : 'Artista desconocido';

    final playedAtLabel = _formatPlayedAt(track);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '$index',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
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
                      child: Image.network(imageUrl, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.music_note, color: Colors.white),
            ),
          ],
        ),
        title: Text(
          track['name'] ?? 'Sin título',
          style: const TextStyle(
            color: Colors.white,
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
              artists,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (playedAtLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                playedAtLabel,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
            const SizedBox(height: 4),
            _buildPlatformChip(platform),
          ],
        ),
        trailing: const Icon(Icons.play_arrow, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

