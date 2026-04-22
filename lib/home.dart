import 'artist_detail_screen.dart';
import 'top_artists_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart'; // IMPORTANTE: Para la cámara y galería
import 'favorites.dart';
import 'widgets/app_bottom_nav.dart';
import 'explore.dart';
import 'user_profile.dart';
import 'createPlaylist.dart';
import 'my_music_screen.dart';
import 'services/api_client.dart'; 
import 'prompt_playlist.dart'; 

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 2});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; 
  
  String _userName = 'Cargando...';
  List<dynamic> _topArtists = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadUserData(); 
  }

  Future<void> _loadUserData() async {
    try {
      final api = ApiClient();
      
      final profile = await api.getSpotifyProfile();
      final name = profile['display_name'] ?? 'Usuario';

      final artistsData = await api.getTopArtists(limit: 4);
      final artistsList = artistsData['items'] ?? [];

      if (mounted) {
        setState(() {
          _userName = name;
          _topArtists = artistsList;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos del home: $e');
      if (mounted) {
        setState(() {
          _userName = 'Usuario'; 
          _isLoadingData = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B69),
      body: _buildBody(),
      extendBody: true,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) return const MyMusicScreen();
    if (_selectedIndex == 1) return const FavoritesScreen();
    if (_selectedIndex == 3) return const ExploreScreen();
    if (_selectedIndex == 4) return const UserProfileScreen();
    
    // Home (índice 2)
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola ${_userName.split(" ")[0]}!', 
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              const Text(
                'Encuentra música nueva',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 30),
              
              _buildSection(
                'Tus artistas favoritos',
                _buildArtistsList(),
                onSeeAllTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const TopArtistsScreen())
                  );
                }
              ),
              
              const SizedBox(height: 30),
              
              _buildSection(
                'Genera playlists',
                _buildCreatePlaylist(),
              ),
              
              const SizedBox(height: 30),
              
              _buildSection(
                'Playlists recomendadas',
                _buildRecommendedPlaylists(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content, {VoidCallback? onSeeAllTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            TextButton(
              onPressed: onSeeAllTap ?? () {}, 
              child: const Text(
                'See all',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        content,
      ],
    );
  }

  Widget _buildArtistsList() {
    if (_isLoadingData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: Color(0xFF9C7CFE)),
        )
      );
    }

    if (_topArtists.isEmpty) {
      return const Text(
        'Escucha más música en Spotify para ver a tus artistas favoritos aquí.',
        style: TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 13),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _topArtists.length,
        itemBuilder: (context, index) {
          final artist = _topArtists[index];
          final name = artist['name'] ?? 'Artista';
          
          String? imageUrl;
          final images = artist['images'] as List?;
          if (images != null && images.isNotEmpty) {
            imageUrl = images.first['url'];
          }

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArtistDetailScreen(artist: artist),
                  ),
                );
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                    child: imageUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 70, 
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, 
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreatePlaylist() {
    return GestureDetector(
      onTap: () {
        showCreatePlaylistBlur(context);
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF9C7CFE).withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9C7CFE).withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crea una nueva\nplaylist',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedPlaylists() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: const DecorationImage(
                image: AssetImage('assets/images/playlist1.png'), 
                fit: BoxFit.cover,
              ),
            ),
            child: const Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Música relajante',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── FUNCIÓN PARA MOSTRAR LA CÁMARA/GALERÍA ──
void _showImagePickerMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2D1B69),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Seleccionar foto',
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  fontFamily: 'Poppins'
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C7CFE).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF9C7CFE)),
                ),
                title: const Text('Tomar foto con la cámara', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                onTap: () async {
                  Navigator.pop(context);
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    // TODO: Navegar a la pantalla de generación con la foto
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C7CFE).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Color(0xFF9C7CFE)),
                ),
                title: const Text('Elegir de la galería', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                onTap: () async {
                  Navigator.pop(context);
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    // TODO: Navegar a la pantalla de generación con la foto
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ── FUNCIÓN DEL PANEL BORROSO SIMÉTRICO ──
void showCreatePlaylistBlur(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar modal',
    barrierColor: Colors.transparent, 
    transitionDuration: const Duration(milliseconds: 350),
    
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1B69),
              borderRadius: BorderRadius.circular(28), // Bordes más suaves
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Center(
                  child: Text(
                    'Crear playlist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                
                Row(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1, // MAGIA: Fuerza a que sea un cuadrado perfecto
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop(); // Cerramos el difuminado
                            _showImagePickerMenu(context); // Abrimos el menú de cámara
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent, // Fondo transparente
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF9C7CFE).withOpacity(0.6), width: 1.5),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face_retouching_natural, color: Colors.white, size: 42),
                                SizedBox(height: 12),
                                Text(
                                  'Escaneo\nfacial', 
                                  textAlign: TextAlign.center, 
                                  style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.bold, height: 1.2)
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1, // MAGIA: Fuerza a que sea un cuadrado perfecto
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PromptPlaylistScreen()),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF9C7CFE),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: const Color(0xFF9C7CFE).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, color: Colors.white, size: 42),
                                SizedBox(height: 12),
                                Text(
                                  'Prompt', 
                                  textAlign: TextAlign.center, 
                                  style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.bold, height: 1.2)
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancelar', style: TextStyle(color: Colors.white.withOpacity(0.6), fontFamily: 'Poppins', fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return Stack(
        children: [
          SizedBox.expand(
            child: FadeTransition(
              opacity: animation,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          ),
        ],
      );
    },
  );
}