import 'package:flutter/material.dart';
import 'home.dart';
import 'widgets/app_bottom_nav.dart';
import 'services/api_client.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  static const _kBg      = Color(0xFF1A0E3B);
  static const _kSurface = Color(0xFF2D1B69);
  static const _kCard    = Color(0xFF3D2A85);
  static const _kAccent  = Color(0xFF9C7CFE);

  final ApiClient _api = ApiClient();

  bool _isLoading = true;
  bool _isSaving  = false;
  bool _isEditing = false;

  String  _displayName  = '';
  String  _dob          = '';
  String  _gender       = '';
  String? _avatarUrl;

  late TextEditingController _nameCtrl;
  late TextEditingController _genderCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl   = TextEditingController();
    _genderCtrl = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _genderCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      // Run both requests in parallel
      final results = await Future.wait([
        _api.getUserProfile().catchError((_) => <String, dynamic>{}),
        _api.getSpotifyProfile().catchError((_) => <String, dynamic>{}),
      ]);
      final local   = results[0];
      final spotify = results[1];

      if (!mounted) return;

      // Prefer Spotify name; fall back to local DB value
      final name = spotify['display_name'] as String? ??
                   local['display_name'] as String? ??
                   '';

      // Extract avatar from Spotify images array
      String? avatar = local['avatar_url'] as String?;
      final images = spotify['images'] as List?;
      if (images != null && images.isNotEmpty) {
        avatar = (images.first as Map<String, dynamic>)['url'] as String?;
      }

      setState(() {
        _displayName = name;
        _dob         = local['dob'] as String? ?? '';
        _gender      = local['gender'] as String? ?? '';
        _avatarUrl   = avatar;
        _nameCtrl.text   = _displayName;
        _genderCtrl.text = _gender;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final p = await _api.updateUserProfile(
        _nameCtrl.text.trim(),
        _dob,
        _genderCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _displayName  = p['display_name'] ?? _displayName;
        _gender       = p['gender'] ?? _gender;
        _isEditing    = false;
        _isSaving     = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Perfil actualizado ✓', style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      debugPrint('Error saving: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al guardar', style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _cancelEdit() {
    setState(() {
      _nameCtrl.text   = _displayName;
      _genderCtrl.text = _gender;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kAccent))
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAvatarSection(),
                          const SizedBox(height: 28),
                          _buildSectionTitle('Información de la cuenta'),
                          const SizedBox(height: 12),
                          _buildField(
                            icon: Icons.person_outline,
                            label: 'Nombre de usuario',
                            ctrl: _nameCtrl,
                            displayValue: _displayName.isNotEmpty ? _displayName : 'Sin nombre',
                            editable: true,
                          ),
                          _buildField(
                            icon: Icons.cake_outlined,
                            label: 'Fecha de nacimiento',
                            ctrl: TextEditingController(text: _dob),
                            displayValue: _dob.isNotEmpty ? _dob : 'No especificada',
                            editable: false,
                            subtitle: 'No editable por seguridad',
                          ),
                          _buildField(
                            icon: Icons.self_improvement_outlined,
                            label: 'Identidad / Género',
                            ctrl: _genderCtrl,
                            displayValue: _gender.isNotEmpty ? _gender : 'No especificado',
                            editable: true,
                          ),
                          const SizedBox(height: 8),
                          _buildSpotifyNote(),
                          if (_isEditing) ...[
                            const SizedBox(height: 28),
                            _buildActionButtons(),
                          ],
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
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Información Personal',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
            ),
          ),
          if (!_isEditing)
            _buildHeaderBtn(
              icon: Icons.edit_outlined,
              color: _kAccent,
              onTap: () => setState(() => _isEditing = true),
              tooltip: 'Editar',
            )
          else ...[
            _buildHeaderBtn(icon: Icons.close, color: Colors.white54, onTap: _cancelEdit, tooltip: 'Cancelar'),
            const SizedBox(width: 4),
            _buildHeaderBtn(icon: Icons.check_circle_outline, color: Colors.greenAccent, onTap: _isSaving ? null : _saveProfile, tooltip: 'Guardar'),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderBtn({required IconData icon, required Color color, required VoidCallback? onTap, required String tooltip}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: _isSaving && tooltip == 'Guardar'
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.greenAccent, strokeWidth: 2))
              : Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  // ── AVATAR SECTION ─────────────────────────────────────────────────────────
  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_kAccent, Color(0xFF7B5EA7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(color: _kAccent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: ClipOval(
                  child: _avatarUrl != null
                      ? Image.network(_avatarUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _defaultAvatar())
                      : _defaultAvatar(),
                ),
              ),
              // Spotify badge
              Positioned(
                bottom: 2, right: 2,
                child: Container(
                  width: 28, height: 28,
                  decoration: const BoxDecoration(color: Color(0xFF1DB954), shape: BoxShape.circle),
                  child: const Icon(Icons.music_note, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _displayName.isNotEmpty ? _displayName : 'Tu nombre',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: Color(0xFF1DB954), size: 13),
                SizedBox(width: 4),
                Text('Conectado con Spotify', style: TextStyle(color: Color(0xFF1DB954), fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() => Container(
    color: _kCard,
    child: const Icon(Icons.person, color: Colors.white54, size: 52),
  );

  // ── SECTION TITLE ──────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) => Text(
    title,
    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Poppins', letterSpacing: 1.2),
  );

  // ── FIELD CARD ─────────────────────────────────────────────────────────────
  Widget _buildField({
    required IconData icon,
    required String label,
    required TextEditingController ctrl,
    required String displayValue,
    required bool editable,
    String? subtitle,
  }) {
    final bool showEdit = _isEditing && editable;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: showEdit ? _kAccent.withOpacity(0.6) : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: editable ? _kAccent.withOpacity(0.15) : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: editable ? _kAccent : Colors.white38, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  showEdit
                      ? TextField(
                          controller: ctrl,
                          style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            hintText: 'Escribe aquí...',
                            hintStyle: TextStyle(color: Colors.white30, fontFamily: 'Poppins'),
                          ),
                          autofocus: true,
                        )
                      : Text(
                          displayValue,
                          style: TextStyle(
                            color: editable ? Colors.white : Colors.white54,
                            fontSize: 15,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontFamily: 'Poppins')),
                  ],
                ],
              ),
            ),
            if (editable && !_isEditing)
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 18)
            else if (!editable)
              Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.2), size: 16),
          ],
        ),
      ),
    );
  }

  // ── SPOTIFY NOTE ───────────────────────────────────────────────────────────
  Widget _buildSpotifyNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white38, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'El nombre de usuario proviene de tu cuenta de Spotify. La fecha de nacimiento solo se puede establecer desde "Configuración de cuenta".',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontFamily: 'Poppins', height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── ACTION BUTTONS ─────────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelEdit,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              disabledBackgroundColor: _kAccent.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Guardar cambios', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}
