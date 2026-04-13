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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _loginWithPlatform(String platform) async {
    try {
      final api = ApiClient();
      final authUrl = api.getAuthUrl(platform);
      
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        // Mostrar diálogo de espera
        if (mounted) {
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
                  Builder(
                    builder: (context) {
                      return Text(
                        'Se abrió tu navegador. Inicia sesión en ${_platformDisplayName(platform)} y autoriza la aplicación.\n\nCuando termines, cierra la ventana del navegador y presiona \"Continuar\".',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(); // Cerrar diálogo
                    
                    // Verificar si se vinculó correctamente
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
                      
                       if (hasPlatform && mounted) {
                         // Login exitoso, ir al home
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
                       } else if (mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                             content: Text('No se detectó la vinculación. Intenta de nuevo.'),
                             backgroundColor: Colors.orange,
                           ),
                         );
                       }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error verificando cuenta: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Continuar',
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
        
        // Abrir navegador
        await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      {'name': 'Deezer', 'key': 'deezer', 'logo': 'assets/svg/deezer.svg'},
      {'name': 'Apple Music', 'key': 'apple', 'logo': 'assets/svg/applemusic.svg'},
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
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
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
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Correo electrónico',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa tu correo';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Contraseña',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu contraseña';
                              }
                              if (value.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _onLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9C7CFE),
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'O inicia sesión con',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildStreamingPlatforms(),
                          const SizedBox(height: 16),
                          Text(
                            'Recomendado: Spotify',
                            style: TextStyle(
                              color: const Color(0xFF1DB954),
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'No tienes una cuenta? ',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                  );
                                },
                                child: const Text(
                                  'Regístrate',
                                  style: TextStyle(
                                    color: Color(0xFF9C7CFE),
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
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