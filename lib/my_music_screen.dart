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

  // ── Colores de plataforma ──────────────────────────────────────────────────
  static const _kAccent  = Color(0xFF9C7CFE);
  static const _kBg      = Color(0xFF2D1B69);
  static const _kSurface = Color(0xFF3D2A85);

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
    setState(() { _isLoading = true; _errorMessage = null; });

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
        if (!hasConnection) continue;
        profiles[platform]  = await service.getUserProfile();
        playlists[platform] = await service.getUserPlaylists();
        favorites[platform] = await service.getUserTopTracks();
        recent[platform]    = await service.getRecentlyPlayed();
      } catch (e) {
        warnings.add(
          'No se pudo cargar ${StreamingService.platformDisplayName(platform)}: $e',
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _connectedPlatforms        = connected;
      _profilesByPlatform        = profiles;
      _playlistsByPlatform       = playlists;
      _favoritesByPlatform       = favorites;
      _recentByPlatform          = recent;
      _hasAnyPlatformConnected   = connected.values.any((v) => v);
      _isLoading                 = false;
      _errorMessage              = warnings.isNotEmpty ? warnings.join('\n') : null;
    });
  }

  Future<void> _connectPlatform(String platform) async {
    try {
      final uri = Uri.parse(ApiClient().getAuthUrl(platform));
      if (!await canLaunchUrl(uri)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace de autenticación')),
        );
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: _kSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Vinculando ${StreamingService.platformDisplayName(platform)}...',
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: _kAccent),
              const SizedBox(height: 16),
              Text(
                'El navegador se abrió. Autoriza la conexión, luego cierra la ventana y presiona "Listo".',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontFamily: 'Poppins'),
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isLinked
                      ? '¡${StreamingService.platformDisplayName(platform)} vinculada!'
                      : 'No se detectó la vinculación. Intenta de nuevo.'),
                  backgroundColor: isLinked ? Colors.green : Colors.orange,
                ));
              },
              child: const Text('Listo',
                  style: TextStyle(color: _kAccent, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error vinculando cuenta: $e')),
      );
    }
  }

  MapEntry<String, Map<String, dynamic>>? get _primaryProfileEntry {
    for (final p in _platformOrder) {
      final profile = _profilesByPlatform[p];
      if (profile != null) return MapEntry(p, profile);
    }
    return null;
  }

  List<Map<String, dynamic>> _aggregateByPlatform(
    Map<String, List<Map<String, dynamic>>> source,
  ) {
    final result = <Map<String, dynamic>>[];
    for (final p in _platformOrder) {
      for (final item in source[p] ?? []) {
        result.add({'platform': p, 'data': item});
      }
    }
    return result;
  }

  String? _formatPlayedAt(Map<String, dynamic> track) {
    final playedAt = track['played_at'];
    if (playedAt is! String) return null;
    try {
      final dt = DateTime.parse(playedAt).toLocal();
      final p = (int v) => v.toString().padLeft(2, '0');
      return 'Reproducida el ${p(dt.day)}/${p(dt.month)} a las ${p(dt.hour)}:${p(dt.minute)}';
    } catch (_) { return null; }
  }

  // ── PLATAFORM BADGE ────────────────────────────────────────────────────────
  Widget _buildPlatformBadge(String platform) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            _platformLogos[platform] ?? _platformLogos['spotify']!,
            width: 13, height: 13,
          ),
          const SizedBox(width: 4),
          Text(
            StreamingService.platformDisplayName(platform),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
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
          if (i != 0) Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: i)),
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _kAccent),
          SizedBox(height: 16),
          Text('Cargando tu música...',
              style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  Widget _buildConnectPlatforms() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Center(child: SvgPicture.asset('assets/svg/spotify.svg', width: 55)),
            ),
            const SizedBox(height: 28),
            const Text('Conecta tus plataformas',
                style: TextStyle(color: Colors.white, fontSize: 26,
                    fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'Vincula Spotify, Deezer o Apple Music para ver tus playlists, favoritos y recientes.',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15, fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ..._platformOrder.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: () => _connectPlatform(p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: p == 'spotify'
                      ? const Color(0xFF1DB954)
                      : p == 'deezer'
                          ? const Color(0xFFEF5466)
                          : const Color(0xFFFA2D48),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  elevation: 0,
                ),
                icon: SvgPicture.asset(_platformLogos[p]!, width: 22, height: 22,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                label: Text('Conectar con ${StreamingService.platformDisplayName(p)}',
                    style: const TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ),
            )),
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontFamily: 'Poppins'),
                    textAlign: TextAlign.center),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Contenido principal ────────────────────────────────────────────────────
  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_errorMessage!,
                  style: const TextStyle(color: Colors.orangeAccent,
                      fontFamily: 'Poppins', fontSize: 12)),
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

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final profile = _primaryProfileEntry?.value;
    final platform = _primaryProfileEntry?.key ?? 'spotify';

    final images   = profile?['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty
        ? (images.first as Map<String, dynamic>)['url'] as String?
        : null;
    final displayName = profile?['display_name'] ?? 'Usuario';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kAccent, width: 2),
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: _kAccent.withOpacity(0.3),
                      child: const Icon(Icons.person, color: Colors.white, size: 28),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Nombre + plataforma
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mi Música',
                    style: TextStyle(color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                const SizedBox(height: 2),
                Text(displayName,
                    style: TextStyle(color: Colors.white.withOpacity(0.55),
                        fontSize: 13, fontFamily: 'Poppins'),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                _buildPlatformBadge(platform),
              ],
            ),
          ),

          // Botón refresh
          IconButton(
            onPressed: _loadStreamingData,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Actualizar',
          ),
        ],
      ),
    );
  }

  // ── TABS ───────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(22),
        ),
        child: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: _kAccent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withOpacity(0.45),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.45),
          labelStyle: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Playlists'),
            Tab(text: 'Favoritos'),
            Tab(text: 'Recientes'),
          ],
        ),
      ),
    );
  }

  // ── PLAYLISTS TAB ──────────────────────────────────────────────────────────
  Widget _buildPlaylistsTab() {
    final aggregated = _aggregateByPlatform(_playlistsByPlatform);
    if (aggregated.isEmpty) return _buildEmptyState('No hay playlists disponibles');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: aggregated.length,
      itemBuilder: (context, index) {
        final entry    = aggregated[index];
        final platform = entry['platform'] as String;
        final playlist = entry['data'] as Map<String, dynamic>;
        return _buildPlaylistItem(platform, playlist);
      },
    );
  }

  Widget _buildPlaylistItem(String platform, Map<String, dynamic> playlist) {
    final images   = playlist['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty
        ? (images.first as Map<String, dynamic>)['url'] as String?
        : null;

    int trackCount = 0;
    try {
      var t = playlist['items'] ?? playlist['tracks'];
      if (t is Map) trackCount = t['total'] ?? 0;
      else if (t is int) trackCount = t;
    } catch (_) {}

    return GestureDetector(
      onTap: () {
        final ownerName = (playlist['owner'] as Map<String, dynamic>?)?['display_name'] ?? 'Spotify';
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlaylistResultScreen(
            title: playlist['name'] ?? 'Sin nombre',
            subtitleUser: 'Creada por $ownerName',
            mood: 'Tu música',
            playlistId: playlist['id'] ?? '',
            imageUrl: imageUrl,
          ),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            // Portada cuadrada
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: imageUrl != null
                  ? Image.network(imageUrl,
                      width: 80, height: 80, fit: BoxFit.cover)
                  : Container(
                      width: 80, height: 80,
                      color: _kAccent.withOpacity(0.2),
                      child: const Icon(Icons.music_note_rounded,
                          color: _kAccent, size: 32),
                    ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist['name'] ?? 'Sin nombre',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('$trackCount canciones',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontFamily: 'Poppins',
                            fontSize: 12)),
                    const SizedBox(height: 6),
                    _buildPlatformBadge(platform),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.3), size: 22),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAVORITOS TAB ──────────────────────────────────────────────────────────
  Widget _buildFavoritesTab() {
    final aggregated = _aggregateByPlatform(_favoritesByPlatform);
    if (aggregated.isEmpty) return _buildEmptyState('No hay canciones favoritas aún');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: aggregated.length,
      itemBuilder: (context, index) {
        final entry    = aggregated[index];
        final platform = entry['platform'] as String;
        final track    = entry['data'] as Map<String, dynamic>;
        return _buildTrackItem(platform, track, index + 1);
      },
    );
  }

  Widget _buildTrackItem(String platform, Map<String, dynamic> track, int index) {
    final album    = track['album'] as Map<String, dynamic>?;
    final images   = album?['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty
        ? (images.first as Map<String, dynamic>)['url'] as String?
        : null;

    final artists = track['artists'] != null
        ? (track['artists'] as List)
            .map((a) => (a as Map)['name'])
            .join(', ')
        : 'Artista desconocido';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          // Número
          SizedBox(
            width: 42,
            child: Text('$index',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),

          // Portada
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl != null
                ? Image.network(imageUrl, width: 52, height: 52, fit: BoxFit.cover)
                : Container(
                    width: 52, height: 52,
                    color: _kAccent.withOpacity(0.2),
                    child: const Icon(Icons.music_note_rounded, color: _kAccent, size: 24),
                  ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track['name'] ?? 'Sin título',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(artists,
                      style: TextStyle(color: Colors.white.withOpacity(0.5),
                          fontFamily: 'Poppins', fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  _buildPlatformBadge(platform),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.25), size: 20),
          ),
        ],
      ),
    );
  }

  // ── RECIENTES TAB ──────────────────────────────────────────────────────────
  Widget _buildRecentTab() {
    final aggregated = _aggregateByPlatform(_recentByPlatform);
    if (aggregated.isEmpty) return _buildEmptyState('Conecta una plataforma para ver tus recientes');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: aggregated.length,
      itemBuilder: (context, index) {
        final entry    = aggregated[index];
        final platform = entry['platform'] as String;
        final track    = entry['data'] as Map<String, dynamic>;
        return _buildRecentItem(platform, track);
      },
    );
  }

  Widget _buildRecentItem(String platform, Map<String, dynamic> track) {
    final album    = track['album'] as Map<String, dynamic>?;
    final images   = album?['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty
        ? (images.first as Map<String, dynamic>)['url'] as String?
        : null;

    final artists = track['artists'] != null
        ? (track['artists'] as List).map((a) => (a as Map)['name']).join(', ')
        : 'Artista desconocido';

    final playedAt = _formatPlayedAt(track);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          // Portada
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            child: imageUrl != null
                ? Image.network(imageUrl, width: 66, height: 66, fit: BoxFit.cover)
                : Container(
                    width: 66, height: 66,
                    color: _kAccent.withOpacity(0.2),
                    child: const Icon(Icons.music_note_rounded, color: _kAccent, size: 28),
                  ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track['name'] ?? 'Sin título',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(artists,
                      style: TextStyle(color: Colors.white.withOpacity(0.5),
                          fontFamily: 'Poppins', fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (playedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(playedAt,
                        style: TextStyle(color: Colors.white.withOpacity(0.35),
                            fontFamily: 'Poppins', fontSize: 11)),
                  ],
                  const SizedBox(height: 5),
                  _buildPlatformBadge(platform),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.play_arrow_rounded,
                color: Colors.white.withOpacity(0.25), size: 24),
          ),
        ],
      ),
    );
  }

  // ── EMPTY STATE ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(color: Colors.white.withOpacity(0.5),
                  fontSize: 15, fontFamily: 'Poppins'),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}