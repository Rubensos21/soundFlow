import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home.dart';
import 'widgets/app_bottom_nav.dart';
import 'services/api_client.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  List<Map<String, dynamic>> _linkedAccounts = [];
  bool _loadingAccounts = true;

  @override
  void initState() {
    super.initState();
    _loadLinkedAccounts();
  }

  Future<void> _loadLinkedAccounts() async {
    try {
      final api = ApiClient();
      final response = await api.getLinkedAccounts();
      setState(() {
        _linkedAccounts = List<Map<String, dynamic>>.from(response['accounts'] ?? []);
        _loadingAccounts = false;
      });
    } catch (e) {
      setState(() {
        _loadingAccounts = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando cuentas: $e')),
        );
      }
    }
  }

  Future<void> _linkAccount(String platform) async {
    try {
      final api = ApiClient();
      final authUrl = api.getAuthUrl(platform);
      
      // Abrir URL en el navegador
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Mostrar diálogo informativo
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF3D2A6D),
              title: const Text(
                'Vinculando cuenta...',
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF9C7CFE)),
                  const SizedBox(height: 16),
                  Text(
                    'Se abrió tu navegador. Una vez que hayas autorizado la conexión, cierra la ventana del navegador y presiona "Listo".',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _loadLinkedAccounts();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verificando cuenta vinculada...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text(
                    'Listo',
                    style: TextStyle(
                      color: Color(0xFF9C7CFE),
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el enlace de autenticación')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error vinculando cuenta: $e')),
        );
      }
    }
  }

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
                  const Text('Configurar Cuenta', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                ],
              ),
              const Divider(color: Colors.white24),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/images/perfil.png', width: 64, height: 64, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Yael Flores', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Poppins')),
                        SizedBox(height: 2),
                        Text('yaelflores69@gmail.com', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins')),
                        Text('User ID: 1279738746', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins')),
                      ],
                    ),
                  )
                ],
              ),

              const SizedBox(height: 16),
              _dividerField('Cambiar correo electronico'),
              _dividerField('Cambiar Contraseña'),
              _dividerField('Información Personal'),
              
              // Cuentas Vinculadas
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cuentas Vinculadas', style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins')),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                      onPressed: _loadLinkedAccounts,
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              if (_loadingAccounts)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF9C7CFE))),
                )
              else
                ..._buildLinkedAccountsSection(),

              const SizedBox(height: 20),
              const Text('Suscripción', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, fontFamily: 'Poppins')),
              const SizedBox(height: 12),
              const Text('Plan', style: TextStyle(color: Colors.white70, fontFamily: 'Poppins')),
              const Text('Free', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _dividerField('Administrar mi suscripción'),

              const SizedBox(height: 40),
              Row(
                children: [
                  const Icon(Icons.delete_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Borrar Cuenta', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
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

  List<Widget> _buildLinkedAccountsSection() {
    final platforms = ['spotify', 'deezer', 'apple'];
    final platformLogos = {
      'spotify': 'assets/svg/spotify.svg',
      'deezer': 'assets/svg/deezer.svg',
      'apple': 'assets/svg/applemusic.svg',
    };
    final platformNames = {
      'spotify': 'Spotify',
      'deezer': 'Deezer',
      'apple': 'Apple Music',
    };

    return platforms.map((platform) {
      final isLinked = _linkedAccounts.any((acc) => acc['platform'] == platform && acc['linked'] == true);
      final account = _linkedAccounts.firstWhere(
        (acc) => acc['platform'] == platform,
        orElse: () => {},
      );

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: SvgPicture.asset(
                platformLogos[platform] ?? 'assets/svg/spotify.svg',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platformNames[platform] ?? platform,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isLinked && account['displayName'] != null)
                    Text(
                      account['displayName'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                ],
              ),
            ),
            if (isLinked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Vinculada',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: () => _linkAccount(platform),
                child: const Text(
                  'Vincular',
                  style: TextStyle(
                    color: Color(0xFF9C7CFE),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _dividerField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins')),
        ),
        const Divider(color: Colors.white24),
      ],
    );
  }
}


