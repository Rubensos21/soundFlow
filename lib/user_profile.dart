import 'package:flutter/material.dart';
import 'home.dart';
import 'widgets/app_bottom_nav.dart';
import 'personal_info.dart';
import 'account_settings.dart';
import 'personal_details.dart';
import 'utils/share_helper.dart';
import 'services/api_client.dart';
import 'playlist_result.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  static const _kBg      = Color(0xFF1A0E3B);
  static const _kSurface = Color(0xFF2D1B69);
  static const _kAccent  = Color(0xFF9C7CFE);
  static const _kGreen   = Color(0xFF1DB954);

  final ApiClient _api = ApiClient();

  String  _displayName = '';
  String? _avatarUrl;
  bool    _isLoading   = true;
  List<Map<String, dynamic>> _myPlaylists = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Fetch live Spotify data (name + avatar) and local playlists in parallel
      final results = await Future.wait([
        _api.getSpotifyProfile().catchError((_) => <String, dynamic>{}),
        _api.getUserProfile().catchError((_) => <String, dynamic>{}),
        _api.getGeneratedPlaylists().catchError((_) => <String, dynamic>{}),
      ]);

      final spotifyProfile = results[0] as Map<String, dynamic>;
      final localProfile   = results[1] as Map<String, dynamic>;
      final playlistsRes   = results[2] as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        // Prefer live Spotify name, fall back to local DB name
        _displayName = spotifyProfile['display_name'] as String? ??
                       localProfile['display_name'] as String? ??
                       'Usuario';

        // Extract avatar URL from Spotify images array
        final images = spotifyProfile['images'] as List?;
        if (images != null && images.isNotEmpty) {
          _avatarUrl = (images.first as Map<String, dynamic>)['url'] as String?;
        } else {
          _avatarUrl = localProfile['avatar_url'] as String?;
        }

        if (playlistsRes.containsKey('playlists')) {
          _myPlaylists = List<Map<String, dynamic>>.from(playlistsRes['playlists'] as List);
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kAccent))
          : CustomScrollView(
              slivers: [
                _buildSliverHeader(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildActionRow(),
                      const SizedBox(height: 16),
                      _buildAccountButton(),
                      const SizedBox(height: 28),
                      _buildPlaylistsSection(),
                    ]),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 4,
        onTap: (i) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: i)),
        ),
      ),
    );
  }

  // ── SLIVER HEADER (avatar + nombre dentro del header animado) ──────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: _kSurface,
      automaticallyImplyLeading: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PersonalInfoScreen()))
                .then((_) => _loadData()),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D2A85), Color(0xFF1A0E3B)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // ── Avatar ──────────────────────────────────────────────────
              Stack(
                children: [
                  Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_kAccent, Color(0xFF7B5EA7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: _kAccent.withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: ClipOval(
                      child: _avatarUrl != null
                          ? Image.network(
                              _avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _defaultAvatar(),
                            )
                          : _defaultAvatar(),
                    ),
                  ),
                  // Spotify badge
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      width: 30, height: 30,
                      decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.music_note, color: Colors.white, size: 17),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // ── Nombre ──────────────────────────────────────────────────
              Text(
                _displayName.isNotEmpty ? _displayName : 'App User',
                style: const TextStyle(
                  color: Colors.white, fontSize: 26,
                  fontWeight: FontWeight.w800, fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 6),
              // Spotify badge label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kGreen.withOpacity(0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: _kGreen, size: 13),
                    SizedBox(width: 5),
                    Text(
                      'Conectado con Spotify',
                      style: TextStyle(color: _kGreen, fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar() => Container(
    color: const Color(0xFF3D2A85),
    child: const Icon(Icons.person, color: Colors.white54, size: 56),
  );

  // ── ROW DE ACCIONES (editar / compartir) ───────────────────────────────────
  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        children: [
          _ActionChip(
            icon: Icons.edit_outlined,
            label: 'Editar perfil',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PersonalDetailsScreen()))
                .then((_) => _loadData()),
          ),
          const SizedBox(width: 10),
          _ActionChip(
            icon: Icons.share_outlined,
            label: 'Compartir',
            onTap: () => ShareHelper.shareText('Mira mi perfil en Sound Flow: $_displayName'),
          ),
        ],
      ),
    );
  }

  // ── BOTÓN AJUSTES ──────────────────────────────────────────────────────────
  Widget _buildAccountButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.manage_accounts_outlined, color: Colors.white70, size: 20),
        label: const Text(
          'Ajustes de Cuenta',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.25)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
        ),
      ),
    );
  }

  // ── SECCIÓN PLAYLISTS ──────────────────────────────────────────────────────
  Widget _buildPlaylistsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Tus Playlists Generadas',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: _kAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Text(
                '${_myPlaylists.length}',
                style: const TextStyle(color: _kAccent, fontWeight: FontWeight.w700, fontFamily: 'Poppins', fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_myPlaylists.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Icon(Icons.queue_music_outlined, color: Colors.white.withOpacity(0.2), size: 40),
                const SizedBox(height: 8),
                Text(
                  'Aún no has generado playlists.\nExplora el Home para crear una.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'Poppins', fontSize: 13, height: 1.5),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _myPlaylists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final pl = _myPlaylists[i];
                return _buildPlaylistCard(pl);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPlaylistCard(Map<String, dynamic> pl) {
    final colors = [
      [const Color(0xFF9C7CFE), const Color(0xFF6A4DDB)],
      [const Color(0xFF1DB954), const Color(0xFF0D8C3A)],
      [const Color(0xFFFF6B6B), const Color(0xFFCC3333)],
      [const Color(0xFFFFB347), const Color(0xFFCC7700)],
    ];
    final idx = (pl['id'] ?? 0).hashCode % colors.length;
    final gradient = colors[idx.abs()];

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlaylistResultScreen(
            title: pl['name'] ?? 'Mi Playlist',
            subtitleUser: _displayName,
            mood: pl['emotion'] ?? pl['method'] ?? 'Generada',
            playlistId: pl['id']?.toString() ?? '',
          ),
        ),
      ),
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.queue_music_rounded, color: Colors.white, size: 28),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pl['name'] ?? 'Playlist',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pl['emotion'] ?? pl['method'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9.5, fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── CHIP DE ACCIÓN ─────────────────────────────────────────────────────────
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
