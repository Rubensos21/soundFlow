import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'prompt_playlist.dart';
import 'playlist_result.dart';
import 'home.dart';
import 'widgets/app_bottom_nav.dart';
import 'services/api_client.dart';

class CreatePlaylistScreen extends StatelessWidget {
  const CreatePlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B69),
      body: SafeArea(
        child: Stack(
          children: [
            // Contenido principal borroso de fondo (placeholder de lista)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 8),
                    Text(
                      'Genera playlists',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Módulo centrado (pixel perfect)
            Align(
              alignment: Alignment.center,
              child: _CreateOptionsCard(),
            ),

            // Botón volver
            Positioned(
              left: 12,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
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

class _CreateOptionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OptionTile(
                  label: 'Escaneo\nfacial',
                  svgAsset: 'assets/svg/EscFacial.svg',
                  onTap: () => _handleFacialScan(context),
                ),
                const SizedBox(width: 16),
                _OptionTile(
                  label: 'Prompt',
                  svgAsset: 'assets/svg/Prompt.svg',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PromptPlaylistScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleFacialScan(BuildContext context) async {
    // Mostrar opción de cámara o galería
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        title: const Text(
          'Seleccionar imagen',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Cámara', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Galería', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    
    if (image == null) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF9C7CFE)),
      ),
    );

    try {
      final api = ApiClient();
      final resp = await api.generatePlaylistFromFacial(image);
      
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Cerrar loading

      final emotion = resp['emotion_detected']?.toString() ?? 'neutral';
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlaylistResultScreen(
            title: 'Playlist generada',
            subtitleUser: 'SoundFlow AI',
            mood: emotion,
            // Agregamos esto: Si tu backend ya devuelve un ID de playlist al crearla, lo usa. Si no, manda vacío.
            playlistId: resp['playlist_id']?.toString() ?? '', 
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Cerrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generando playlist: $e')),
      );
    }
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String svgAsset;
  final VoidCallback? onTap;

  const _OptionTile({required this.label, required this.svgAsset, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        height: 148,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF9C7CFE),
              Color(0xFF7E61FB),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C7CFE).withOpacity(0.35),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF9C7CFE).withOpacity(0.15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                svgAsset,
                width: 72,
                height: 72,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


