import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'main.dart';
import 'widgets/app_bottom_nav.dart';
import 'account_settings.dart';
import 'personal_details.dart';
import 'services/api_client.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  static const _kBg     = Color(0xFF1A0E3B);
  static const _kCard   = Color(0xFF2D1B69);
  static const _kAccent = Color(0xFF9C7CFE);
  static const _kGreen  = Color(0xFF1DB954);

  final ApiClient _api = ApiClient();

  bool    _isLoading   = true;
  String  _displayName = '';
  String? _avatarUrl;
  int     _followers   = 0;
  int     _following   = 0;
  String  _spotifyId   = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _api.getSpotifyProfile().catchError((_) => <String, dynamic>{}),
        _api.getUserProfile().catchError((_) => <String, dynamic>{}),
      ]);
      final sp    = results[0] as Map<String, dynamic>;
      final local = results[1] as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _displayName = sp['display_name'] as String? ??
                       local['display_name'] as String? ?? '';
        _spotifyId   = sp['id'] as String? ?? '';

        final images = sp['images'] as List?;
        if (images != null && images.isNotEmpty) {
          _avatarUrl = (images.first as Map<String, dynamic>)['url'] as String?;
        }

        // Spotify followers (followers.total)
        final followersObj = sp['followers'];
        if (followersObj is Map) {
          _followers = (followersObj['total'] as num?)?.toInt() ?? 0;
        }

        // Spotify doesn't expose "following" count directly in /me,
        // but we can show it as a placeholder or from our own data.
        _following = 0;

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading info: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _kAccent))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileCard(),
                          const SizedBox(height: 20),
                          _buildSection('Preferencias', [
                            _menuItem(context, 'assets/svg/pantalla.svg',       'Pantalla',            Icons.chevron_right),
                            _menuItem(context, 'assets/svg/notificaciones.svg', 'Notificaciones',       Icons.chevron_right),
                          ]),
                          _buildSection('Privacidad', [
                            _menuItem(context, 'assets/svg/privacidad.svg',     'Tu privacidad en SoundFlow', Icons.chevron_right),
                            _switchTile('assets/svg/perfilPrivado.svg',         'Perfil Privado'),
                          ]),
                          _buildSection('Más', [
                            _menuItem(context, 'assets/svg/Dispositivos.svg',   'Dispositivos',         Icons.chevron_right),
                            _menuItem(context, 'assets/svg/mejorar.svg',        'Ayúdanos a mejorar',   Icons.chevron_right),
                            _menuItem(context, 'assets/svg/configurar.svg',     'Acerca de',            Icons.chevron_right),
                          ]),
                          const SizedBox(height: 28),
                          _buildLogoutBtn(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 4,
        onTap: (i) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: i)),
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    decoration: BoxDecoration(
      color: _kCard,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const Expanded(
          child: Text('Ajustes', style: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Poppins',
          )),
        ),
      ],
    ),
  );

  // ── PROFILE CARD ───────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PersonalDetailsScreen()))
          .then((_) => _loadData()),
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [_kAccent, Color(0xFF7B5EA7)]),
                    boxShadow: [BoxShadow(color: _kAccent.withOpacity(0.35), blurRadius: 12)],
                  ),
                  child: ClipOval(
                    child: _avatarUrl != null
                        ? Image.network(_avatarUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _defaultAvatar())
                        : _defaultAvatar(),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.music_note, color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Name + stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_displayName.isNotEmpty ? _displayName : 'Tu nombre',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Poppins'),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Seguidores — Spotify solo devuelve followers
                  Row(
                    children: [
                      _statBadge(Icons.people_outline, '$_followers Seguidores'),
                    ],
                  ),
                  if (_spotifyId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text('ID: $_spotifyId',
                        style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10, fontFamily: 'Poppins'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar() => Container(
    color: const Color(0xFF3D2A85),
    child: const Icon(Icons.person, color: Colors.white54, size: 32),
  );

  Widget _statBadge(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.white54, size: 13),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'Poppins')),
    ],
  );

  // ── SECTION ────────────────────────────────────────────────────────────────
  Widget _buildSection(String title, List<Widget> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
        child: Text(title, style: TextStyle(
          color: Colors.white.withOpacity(0.45), fontSize: 11,
          fontFamily: 'Poppins', fontWeight: FontWeight.w600, letterSpacing: 1.2,
        )),
      ),
      Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(children: items),
      ),
    ],
  );

  Widget _menuItem(BuildContext context, String svg, String label, IconData trailing) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (label == 'Tu privacidad en SoundFlow') return;
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => label == 'Dispositivos' || label == 'Pantalla' || label == 'Notificaciones' || label == 'Acerca de'
                ? const AccountSettingsScreen()
                : const PersonalDetailsScreen(),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            SvgPicture.asset(svg, width: 22, height: 22,
              colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn)),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 14))),
            Icon(trailing, color: Colors.white.withOpacity(0.25), size: 18),
          ]),
        ),
      ),
    );
  }

  Widget _switchTile(String svg, String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Row(children: [
      SvgPicture.asset(svg, width: 22, height: 22,
        colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn)),
      const SizedBox(width: 14),
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 14))),
      Switch(value: false, activeColor: _kAccent, onChanged: (_) {}),
    ]),
  );

  // ── LOGOUT ─────────────────────────────────────────────────────────────────
  Widget _buildLogoutBtn() => SizedBox(
    width: double.infinity, height: 48,
    child: OutlinedButton.icon(
      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
      label: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent, fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: _logout,
    ),
  );
}
