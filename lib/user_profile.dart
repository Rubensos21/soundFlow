import 'package:flutter/material.dart';
import 'home.dart';
import 'widgets/app_bottom_nav.dart';
import 'personal_info.dart';
import 'account_settings.dart';
import 'personal_details.dart';
import 'utils/share_helper.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B69),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset('assets/images/perfil.png', width: 180, height: 180, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Yael Flores',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '4 seguidores | 6 seguidos',
                      style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PersonalDetailsScreen()),
                            );
                          },
                          child: const _RoundIcon(icon: Icons.edit),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            ShareHelper.shareText('Mira mi perfil en Sound Flow: Yael Flores');
                          },
                          child: const _RoundIcon(icon: Icons.share_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.6)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
                          );
                        },
                        child: const Text('Ajustes de Cuenta', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Playlists guardadas',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: const Text('13', style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 6,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (_, i) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset('assets/images/playlist1.png', width: 120, height: 80, fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 6),
                            const Text('Musica relajante', style: TextStyle(color: Colors.white, fontSize: 11.5, fontFamily: 'Poppins')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(color: Color(0xFF9C7CFE), shape: BoxShape.circle),
                child: const Icon(Icons.account_circle, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 4,
        onTap: (i) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: i)));
        },
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  const _RoundIcon({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}


