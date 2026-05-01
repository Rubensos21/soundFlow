import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home.dart';
import 'signup_screen.dart';
import 'services/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sound Flow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF9C27B0),
          secondary: const Color(0xFF2D1B69),
          background: const Color(0xFF2D1B69),
          surface: const Color(0xFF2D1B69),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _loginWithPlatform(String platform) async {
    try {
      final api = ApiClient();
      final authUrl = api.getAuthUrl(platform);
      
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        // Abrir navegador
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        if (mounted) {
          Timer? pollingTimer;
          bool isDialogShowing = true;
          
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF3D2A6D),
              title: Text(
                'Iniciando sesión con ${_platformDisplayName(platform)}...',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF9C7CFE)),
                  const SizedBox(height: 16),
                  Text(
                    'Se abrió tu navegador. Inicia sesión en ${_platformDisplayName(platform)} y cuando detecte que se inicio correctamente se quite la pantalla y redireccione a inicio directamente',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ).then((_) {
            isDialogShowing = false;
            pollingTimer?.cancel();
          });

          pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
            if (!isDialogShowing) {
              timer.cancel();
              return;
            }
            try {
              final accounts = await api.getLinkedAccounts();
              final linkedAccounts = List<Map<String, dynamic>>.from(
                accounts['accounts'] ?? []
              );
              
              final hasPlatform = linkedAccounts.any((acc) {
                final matchesPlatform = acc['platform'] == platform;
                final isLinked = acc['linked'] == true;
                final isVerified = acc.containsKey('verified')
                    ? acc['verified'] == true
                    : true;
                return matchesPlatform && isLinked && isVerified;
              });
              
              if (hasPlatform && isDialogShowing) {
                timer.cancel();
                isDialogShowing = false;
                if (mounted) {
                  Navigator.of(context).pop(); // Cerramos el diálogo
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(initialIndex: 0),
                    ),
                    (route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('¡${_platformDisplayName(platform)} vinculada exitosamente!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            } catch (e) {
              // Ignorar errores de polling
            }
          });
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
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _platformDisplayName(String platform) {
    switch (platform) {
      case 'spotify':
        return 'Spotify';
      case 'deezer':
        return 'Deezer';
      case 'apple':
        return 'Apple Music';
      default:
        return platform;
    }
  }

  Color _platformAccentColor(String platform) {
    switch (platform) {
      case 'spotify':
        return const Color(0xFF1DB954);
      case 'deezer':
        return const Color(0xFFEF5466);
      case 'apple':
        return const Color(0xFFFA2D48);
      default:
        return Colors.white.withOpacity(0.6);
    }
  }

  Widget _buildStreamingPlatforms() {
    final platforms = [
      {'name': 'Spotify', 'key': 'spotify', 'logo': 'assets/svg/spotify.svg'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: platforms.map((platform) {
        final key = platform['key'] as String;
        final accentColor = _platformAccentColor(key);
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: GestureDetector(
            onTap: () => _loginWithPlatform(key),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentColor,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SvgPicture.asset(
                  platform['logo'] as String,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    const Column(
                      children: [
                        Text(
                          'SOUND',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'FLOW',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                    Column(
                      children: [
                        const Text(
                          'Inicia Sesión con Spotify',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildStreamingPlatforms(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}