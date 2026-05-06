import 'artist_detail_screen.dart';
import 'top_artists_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'favorites.dart';
import 'widgets/app_bottom_nav.dart';
import 'explore.dart';
import 'user_profile.dart';
import 'createPlaylist.dart';
import 'my_music_screen.dart';
import 'services/api_client.dart';
import 'prompt_playlist.dart';
import 'facial_scan_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 2});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  String _userName = '';
  List<dynamic> _topArtists = [];
  bool _isLoadingData = true;

  static const _kAccent  = Color(0xFF9C7CFE);
  static const _kBg      = Color(0xFF2D1B69);
  static const _kSurface = Color(0xFF3D2A85);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final api = ApiClient();
      final profile     = await api.getSpotifyProfile();
      final artistsData = await api.getTopArtists(limit: 4);
      if (mounted) {
        setState(() {
          _userName    = profile['display_name'] ?? 'Usuario';
          _topArtists  = artistsData['items'] ?? [];
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos del home: $e');
      if (mounted) setState(() { _userName = 'Usuario'; _isLoadingData = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: _buildBody(),
      extendBody: true,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) return const MyMusicScreen();
    if (_selectedIndex == 1) return const FavoritesScreen();
    if (_selectedIndex == 3) return const ExploreScreen();
    if (_selectedIndex == 4) return const UserProfileScreen();
    return _buildHome();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HOME
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHome() {
    final firstName = _userName.isNotEmpty ? _userName.split(' ')[0] : '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Saludo ───────────────────────────────────────────────────
            _isLoadingData
                ? Container(
                    height: 36,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      style: const TextStyle(fontFamily: 'Poppins'),
                      children: [
                        const TextSpan(
                          text: 'Hola ',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, color: Colors.white70),
                        ),
                        TextSpan(
                          text: '$firstName!',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 4),
            const Text(
              'Encuentra música nueva',
              style: TextStyle(fontSize: 14, color: Colors.white54, fontFamily: 'Poppins'),
            ),

            const SizedBox(height: 32),

            // ── Artistas favoritos ───────────────────────────────────────
            _buildSectionHeader(
              'Tus artistas favoritos',
              onSeeAll: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const TopArtistsScreen())),
            ),
            const SizedBox(height: 14),
            _buildArtistsList(),

            const SizedBox(height: 32),

            // ── Genera playlists ─────────────────────────────────────────
            _buildSectionHeader('Genera playlists'),
            const SizedBox(height: 14),
            _buildCreatePlaylistCard(),

            const SizedBox(height: 32),

            // ── Playlists recomendadas (próximamente) ────────────────────
            _buildSectionHeader('Playlists recomendadas'),
            const SizedBox(height: 14),
            _buildRecommendedPlaceholder(),
          ],
        ),
      ),
    );
  }

  // ── SECTION HEADER ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins')),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'Ver todo',
              style: TextStyle(
                  fontSize: 13,
                  color: _kAccent.withOpacity(0.85),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  // ── ARTISTAS ───────────────────────────────────────────────────────────────
  Widget _buildArtistsList() {
    if (_isLoadingData) {
      return SizedBox(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 56, height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_topArtists.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(
          'Escucha más música en Spotify para ver tus artistas favoritos aquí.',
          style: TextStyle(color: Colors.white.withOpacity(0.5),
              fontFamily: 'Poppins', fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _topArtists.length,
        itemBuilder: (context, index) {
          final artist = _topArtists[index];
          final name   = artist['name']?.toString() ?? 'Artista';
          final images = artist['images'] as List?;
          final imageUrl = images != null && images.isNotEmpty
              ? images.first['url'] as String?
              : null;

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ArtistDetailScreen(artist: artist)),
              ),
              child: Column(
                children: [
                  // Avatar con borde degradado
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _kAccent.withOpacity(0.5), width: 2),
                    ),
                    child: ClipOval(
                      child: imageUrl != null
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : Container(
                              color: _kAccent.withOpacity(0.2),
                              child: const Icon(Icons.person,
                                  color: Colors.white54, size: 32),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 72,
                    child: Text(
                      name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── CREAR PLAYLIST ─────────────────────────────────────────────────────────
  Widget _buildCreatePlaylistCard() {
    return GestureDetector(
      onTap: () => showCreatePlaylistBlur(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_kAccent.withOpacity(0.35), _kAccent.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kAccent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: _kAccent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: _kAccent.withOpacity(0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Crea una nueva playlist',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins')),
                  SizedBox(height: 2),
                  Text('Por detección facial o con un prompt',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontFamily: 'Poppins')),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.3), size: 22),
          ],
        ),
      ),
    );
  }

  // ── PLAYLISTS RECOMENDADAS — placeholder hasta integrar Spotify ────────────
  Widget _buildRecommendedPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(Icons.queue_music_rounded,
              size: 40, color: Colors.white.withOpacity(0.18)),
          const SizedBox(height: 12),
          Text(
            'Próximamente',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'playlists recomendadas\npor Spotify según tu gusto musical.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontFamily: 'Poppins',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FUNCIONES GLOBALES (fuera del State)
// ═══════════════════════════════════════════════════════════════════════════

void _showImagePickerMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2D1B69),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Seleccionar foto',
                style: TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            const SizedBox(height: 24),
            _PickerOption(
              icon: Icons.camera_alt,
              label: 'Tomar foto con la cámara',
              onTap: () async {
                Navigator.pop(context);
                final image = await ImagePicker().pickImage(source: ImageSource.camera);
                if (image != null) { /* TODO */ }
              },
            ),
            const SizedBox(height: 8),
            _PickerOption(
              icon: Icons.photo_library,
              label: 'Elegir de la galería',
              onTap: () async {
                Navigator.pop(context);
                final image = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (image != null) { /* TODO */ }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF9C7CFE).withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF9C7CFE)),
      ),
      title: Text(label,
          style: const TextStyle(color: Colors.white,
              fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

void showCreatePlaylistBlur(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar modal',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1B69),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Crear playlist',
                    style: TextStyle(color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                const SizedBox(height: 28),
                Row(
                  children: [
                    // Escaneo facial
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const FacialScanScreen()),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFF9C7CFE).withOpacity(0.5),
                                  width: 1.5),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face_retouching_natural,
                                    color: Colors.white, size: 40),
                                SizedBox(height: 12),
                                Text('Escaneo\nfacial',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        height: 1.2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Prompt
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const PromptPlaylistScreen()));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF9C7CFE),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF9C7CFE).withOpacity(0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4)),
                              ],
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    color: Colors.white, size: 40),
                                SizedBox(height: 12),
                                Text('Prompt',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        height: 1.2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar',
                      style: TextStyle(color: Colors.white.withOpacity(0.5),
                          fontFamily: 'Poppins', fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return Stack(
        children: [
          SizedBox.expand(
            child: FadeTransition(
              opacity: animation,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(color: Colors.black.withOpacity(0.4)),
              ),
            ),
          ),
          FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        ],
      );
    },
  );
}