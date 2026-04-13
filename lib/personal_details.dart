import 'package:flutter/material.dart';
import 'home.dart';
import 'widgets/app_bottom_nav.dart';

class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B69),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 6),
                  const Text('Información Personal', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.7)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Actualizar Imagen', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/images/perfil.png', width: 64, height: 64, fit: BoxFit.cover),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _field('Nombre de Usuario', 'Yael Flores'),
              _field('Fecha de Nacimiento', '19/05/2005'),
              _field('Identidad', 'Masculino'),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 4,
        onTap: (i) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: i))),
      ),
    );
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontFamily: 'Poppins')),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          const Divider(color: Colors.white24),
        ],
      ),
    );
  }
}


