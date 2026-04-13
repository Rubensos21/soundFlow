import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home.dart';
import 'widgets/app_bottom_nav.dart';
import 'account_settings.dart';
import 'personal_details.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B69),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Información Personal',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset('assets/images/perfil.png', width: 64, height: 64, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Yael Flores', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Poppins')),
                            SizedBox(height: 4),
                            Text('4 Seguidores | 6 Seguidos', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins')),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24),

                    _sectionTitle('Preferencias'),
                    _item(context, 'assets/svg/pantalla.svg', 'Pantalla'),
                    _item(context, 'assets/svg/notificaciones.svg', 'Notificaciones'),

                    const SizedBox(height: 10),
                    _sectionTitle('Privacidad'),
                    _item(context, 'assets/svg/privacidad.svg', 'Tu privacidad en SoundFlow', trailing: Icons.chevron_right),
                    _switchItem('assets/svg/perfilPrivado.svg', 'Perfil Privado'),

                    const SizedBox(height: 10),
                    _sectionTitle('Más'),
                    _item(context, 'assets/svg/Dispositivos.svg', 'Dispositivos', trailing: Icons.chevron_right),
                    _item(context, 'assets/svg/mejorar.svg', 'Ayudanos a mejorar', trailing: Icons.chevron_right),
                    _item(context, 'assets/svg/configurar.svg', 'About', trailing: Icons.chevron_right),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.15),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {},
                        child: const Text('Salir', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 4,
        onTap: (i) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: i))),
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Poppins')),
    );
  }

  Widget _item(BuildContext context, String svg, String label, {IconData? trailing}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      leading: SvgPicture.asset(svg, width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
      title: Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'Poppins')),
      trailing: trailing != null ? Icon(trailing, color: Colors.white) : null,
      onTap: () {
        if (label == 'Tu privacidad en SoundFlow') return;
        if (label == 'Pantalla' || label == 'Notificaciones' || label == 'Dispositivos' || label == 'About') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountSettingsScreen()));
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PersonalDetailsScreen()));
        }
      },
    );
  }

  Widget _switchItem(String svg, String label) {
    return Row(
      children: [
        SvgPicture.asset(svg, width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
        const SizedBox(width: 16),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'))),
        Switch(
          value: false,
          activeColor: const Color(0xFF9C7CFE),
          onChanged: (v) {},
        ),
      ],
    );
  }
}


