import 'package:flutter/material.dart';
import 'generated_playlist_detail.dart';
import 'home.dart';
import 'widgets/app_bottom_nav.dart';
import 'services/api_client.dart';

class PromptPlaylistScreen extends StatefulWidget {
  const PromptPlaylistScreen({super.key});

  @override
  State<PromptPlaylistScreen> createState() => _PromptPlaylistScreenState();
}

class _PromptPlaylistScreenState extends State<PromptPlaylistScreen> {
  static const _kAccent  = Color(0xFF9C7CFE);
  static const _kBg      = Color(0xFF2D1B69);
  static const _kSurface = Color(0xFF3D2A85);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _loading = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSelectSuggestion(String text) {
    setState(() => _controller.text = text);
    _focusNode.unfocus();
  }

  void _onGenerate() {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;
    _focusNode.unfocus();
    _generatePrompt(prompt);
  }

  Future<void> _generatePrompt(String prompt) async {
    setState(() => _loading = true);
    try {
      final resp = await ApiClient().generatePlaylistFromPrompt(prompt);
      final playlistId   = resp['playlist_id'] as int?;
      final playlistName = resp['playlist_name']?.toString() ?? 'Playlist generada';
      final tracksCount  = resp['tracks_count'] as int? ?? 0;

      if (!mounted) return;
      setState(() => _loading = false);

      _showSuccessDialog(playlistId, playlistName, tracksCount);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generando playlist: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showSuccessDialog(int? playlistId, String playlistName, int tracksCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF66BB6A), size: 26),
            SizedBox(width: 10),
            Text('¡Playlist Creada!',
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(playlistName,
                style: const TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
            const SizedBox(height: 6),
            Text('Se generaron $tracksCount canciones basadas en tu prompt',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontFamily: 'Poppins', fontSize: 13)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF66BB6A).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF66BB6A).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bookmark_rounded, color: Color(0xFF66BB6A), size: 16),
                  SizedBox(width: 6),
                  Text('Guardada en tus Favoritos',
                      style: TextStyle(color: Color(0xFF66BB6A), fontSize: 12,
                          fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.of(context).pop(); Navigator.of(context).pop(); },
            child: Text('Cerrar',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (playlistId != null) {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => GeneratedPlaylistDetailScreen(playlistId: playlistId)));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Ver Playlist',
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  // Ícono decorativo
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _kAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: _kAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Crear playlist',
                            style: TextStyle(color: Colors.white, fontSize: 20,
                                fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                        Text('Describe lo que quieres escuchar',
                            style: TextStyle(color: Colors.white54, fontSize: 12,
                                fontFamily: 'Poppins')),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Campo de texto ───────────────────────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _kSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _isFocused
                              ? _kAccent.withOpacity(0.7)
                              : Colors.white.withOpacity(0.08),
                          width: _isFocused ? 1.5 : 1,
                        ),
                        boxShadow: _isFocused
                            ? [BoxShadow(
                                color: _kAccent.withOpacity(0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 4))]
                            : null,
                      ),
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.edit_note_rounded,
                                  color: _isFocused ? _kAccent : Colors.white38,
                                  size: 18),
                              const SizedBox(width: 6),
                              Text('Tu idea',
                                  style: TextStyle(
                                    color: _isFocused ? _kAccent : Colors.white38,
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            maxLines: 3,
                            style: const TextStyle(
                                color: Colors.white, fontFamily: 'Poppins', fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Ej: canciones para un road trip nocturno...',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.25),
                                  fontFamily: 'Poppins',
                                  fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Botón generar ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _onGenerate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kAccent,
                          disabledBackgroundColor: _kAccent.withOpacity(0.4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          shadowColor: _kAccent.withOpacity(0.4),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Generar playlist',
                                      style: TextStyle(fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Poppins')),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Sugerencias ──────────────────────────────────────
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                            color: Colors.white38, size: 16),
                        const SizedBox(width: 6),
                        const Text('Sugerencias',
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Poppins')),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Sugerencias en grid 2x2 + 1
                    _buildSuggestions(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onTap: (i) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: i)),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      _SuggestionData(
        emoji: '🎯',
        title: 'Focus',
        description: 'Lo-fi para estudiar o concentrarse',
        prompt: 'Canciones lo-fi instrumentales para concentrarme y estudiar',
        color: const Color(0xFF45B7D1),
      ),
      _SuggestionData(
        emoji: '💜',
        title: 'Amor',
        description: 'R&B y pop romántico',
        prompt: 'Canciones de amor en R&B y pop para una cita romántica',
        color: const Color(0xFFFF6B9D),
      ),
      _SuggestionData(
        emoji: '🌙',
        title: 'Sad',
        description: 'Para esos momentos melancólicos',
        prompt: 'Canciones tristes melancólicas de indie y pop para llorar',
        color: const Color(0xFF7986CB),
      ),
      _SuggestionData(
        emoji: '⚡',
        title: 'Energía',
        description: 'Trap y reggaeton para el gym',
        prompt: 'Canciones energéticas de trap y reggaeton para entrenar',
        color: const Color(0xFFFF7043),
      ),
      _SuggestionData(
        emoji: '🌅',
        title: 'Mañana',
        description: 'Acústico para empezar el día',
        prompt: 'Canciones acústicas tranquilas para empezar la mañana con energía',
        color: const Color(0xFFFFB74D),
      ),
    ];

    return Column(
      children: [
        // Fila de 3
        Row(
          children: suggestions.take(3).map((s) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: s == suggestions[2] ? 0 : 10),
              child: _SuggestionCard(
                data: s,
                onTap: () => _onSelectSuggestion(s.prompt),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 10),
        // Fila de 2
        Row(
          children: suggestions.skip(3).map((s) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: s == suggestions[4] ? 0 : 10),
              child: _SuggestionCard(
                data: s,
                onTap: () => _onSelectSuggestion(s.prompt),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

// ── Suggestion Data ──────────────────────────────────────────────────────────
class _SuggestionData {
  final String emoji;
  final String title;
  final String description;
  final String prompt;
  final Color color;

  const _SuggestionData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.prompt,
    required this.color,
  });
}

// ── Suggestion Card ──────────────────────────────────────────────────────────
class _SuggestionCard extends StatelessWidget {
  final _SuggestionData data;
  final VoidCallback? onTap;

  const _SuggestionCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: data.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: data.color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(data.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 3),
            Text(data.description,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontFamily: 'Poppins',
                    height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}