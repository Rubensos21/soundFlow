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
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSelectSuggestion(String text) {
    setState(() {
      _controller.text = text;
    });
  }

  void _onGenerate() {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;
    _generatePrompt(prompt);
  }

  Future<void> _generatePrompt(String prompt) async {
    setState(() => _loading = true);
    try {
      final api = ApiClient();
      final resp = await api.generatePlaylistFromPrompt(prompt);
      
      final playlistId = resp['playlist_id'] as int?;
      final playlistName = resp['playlist_name']?.toString() ?? 'Playlist generada';
      final tracksCount = resp['tracks_count'] as int? ?? 0;
      
      if (!mounted) return;
      
      setState(() => _loading = false);
      
      // Mostrar diálogo de éxito
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF3D2A6D),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF66BB6A), size: 28),
              SizedBox(width: 12),
              Text(
                '¡Playlist Creada!',
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playlistName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Se generaron $tracksCount canciones basadas en tu prompt',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '✨ La playlist se guardó en tus Favoritos',
                style: TextStyle(
                  color: const Color(0xFF66BB6A),
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Volver al home
              },
              child: const Text(
                'Cerrar',
                style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (playlistId != null) {
                  // Navegar a la pantalla de detalles
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => GeneratedPlaylistDetailScreen(playlistId: playlistId),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C7CFE),
              ),
              child: const Text(
                'Ver Playlist',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generando playlist: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B69),
      body: SafeArea(
        child: Stack(
          children: [
            // Contenido
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Crea una playlist con palabras',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Escribe tu idea o escoge una de nuestras sugerencias',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white70,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo de texto
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFB7A8E9).withOpacity(0.35),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: TextField(
                        controller: _controller,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                        decoration: const InputDecoration(
                          hintText: 'Ingresa tu idea',
                          hintStyle: TextStyle(color: Color(0xFFE5E1F6), fontFamily: 'Poppins'),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Botón generar
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _onGenerate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7E61FB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                        ),
                        child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Generar'),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Divider(color: Colors.white.withOpacity(0.25), thickness: 1),
                    const SizedBox(height: 14),

                    const Text(
                      'Sugerencias',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _SuggestionCard(
                            title: 'Focus',
                            description: 'Genera un mix de\nlo-fi para estudiar',
                            onTap: () => _onSelectSuggestion('Focus - lo-fi para estudiar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SuggestionCard(
                            title: 'Amor',
                            description: 'Crea un mix de\nde amor R&B',
                            onTap: () => _onSelectSuggestion('Amor - R&B romántico'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SuggestionCard(
                            title: 'Sad',
                            description: 'Pon junto classic rock\ny Pop sobre tristeza',
                            onTap: () => _onSelectSuggestion('Sad - mood triste'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Botón cerrar (X) por encima del contenido
            Positioned(
              right: 12,
              top: 6,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onTap: (i) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: i)),
          );
        },
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _SuggestionCard({required this.title, required this.description, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      height: 116,
      decoration: BoxDecoration(
        color: const Color(0xFFB7A8E9).withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                height: 1.25,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ),
          )
        ],
      ),
    ),
    );
  }
}


