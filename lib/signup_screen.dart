import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home.dart';
import 'services/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  List<String> _linkedPlatforms = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _linkPlatform(String platform) async {
    try {
      final api = ApiClient();
      final authUrl = api.getAuthUrl(platform);
      
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
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // Verificar si se vinculó
                    try {
                      final accounts = await api.getLinkedAccounts();
                      final linkedAccounts = List<Map<String, dynamic>>.from(accounts['accounts'] ?? []);
                      setState(() {
                        _linkedPlatforms = linkedAccounts
                            .where((acc) {
                              final isLinked = acc['linked'] == true;
                              final isVerified = acc.containsKey('verified')
                                  ? acc['verified'] == true
                                  : true;
                              return isLinked && isVerified;
                            })
                            .map((acc) => acc['platform'].toString())
                            .toList();
                      });
                      if (_linkedPlatforms.contains(platform)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('¡Cuenta vinculada exitosamente!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      // Error al verificar, asumir que se vinculó
                    }
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

  void _onSignUp() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      // Simular registro (aquí iría la lógica real de registro)
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B69),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Crear cuenta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Nombre completo
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Nombre completo',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Correo electrónico
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Correo electrónico',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu correo';
                      }
                      if (!value.contains('@')) {
                        return 'Correo inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Contraseña',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
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
                  const SizedBox(height: 16),
                  
                  // Confirmar contraseña
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Confirmar contraseña',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirma tu contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Vincular plataformas
                  const Text(
                    'Vincular plataformas de streaming',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPlatformButtons(),
                  
                  if (_linkedPlatforms.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _linkedPlatforms.map((platform) {
                        return Chip(
                          label: Text(
                            platform,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: Colors.green.withOpacity(0.2),
                          deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
                          onDeleted: () {
                            setState(() {
                              _linkedPlatforms.remove(platform);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Botón de registro
                  ElevatedButton(
                    onPressed: _isLoading ? null : _onSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C7CFE),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Crear cuenta',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Enlace a login
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '¿Ya tienes una cuenta? ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Inicia sesión',
                            style: TextStyle(
                              color: Color(0xFF9C7CFE),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformButtons() {
    final platforms = [
      {'name': 'Spotify', 'logo': 'assets/svg/spotify.svg', 'key': 'spotify'},
      {'name': 'Deezer', 'logo': 'assets/svg/deezer.svg', 'key': 'deezer'},
      {'name': 'Apple Music', 'logo': 'assets/svg/applemusic.svg', 'key': 'apple'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: platforms.map((platform) {
        final isLinked = _linkedPlatforms.contains(platform['key']);
        return GestureDetector(
          onTap: () => _linkPlatform(platform['key'] as String),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isLinked 
                  ? Colors.green.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLinked 
                    ? Colors.green 
                    : Colors.white.withOpacity(0.2),
                width: isLinked ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: SvgPicture.asset(
                    platform['logo'] as String,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  platform['name'] as String,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isLinked)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

