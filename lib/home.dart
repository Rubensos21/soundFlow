import 'artist_detail_screen.dart';
import 'top_artists_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'favorites.dart';
import 'widgets/app_bottom_nav.dart';
import 'explore.dart';
import 'user_profile.dart';
import 'createPlaylist.dart';
import 'my_music_screen.dart';
import 'services/api_client.dart'; // IMPORTANTE: Agregamos el cliente

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 2});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // Por defecto el Home (índice 2)
  
  // Nuevas variables para guardar los datos reales
  String _userName = 'Cargando...';
  List<dynamic> _topArtists = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadUserData(); // Mandamos a traer los datos al abrir la pantalla
  }

  // Función mágica que trae tus datos de Spotify
  Future<void> _loadUserData() async {
    try {
      final api = ApiClient();
      
      // 1. Obtenemos tu perfil (Nombre)
      final profile = await api.getSpotifyProfile();
      final name = profile['display_name'] ?? 'Usuario';

      // 2. Obtenemos tus artistas favoritos
      final artistsData = await api.getTopArtists(limit: 4);
      final artistsList = artistsData['items'] ?? [];

      // 3. Actualizamos la pantalla
      if (mounted) {
        setState(() {
          _userName = name;
          _topArtists = artistsList;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('Error cargando datos del home: $e');
      if (mounted) {
        setState(() {
          _userName = 'Usuario'; // Si falla, te llama "Usuario"
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
              
              // 1. TUS ARTISTAS FAVORITOS
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
              
              // 2. ¡AQUÍ ESTÁ LA SECCIÓN RESTAURADA DE CREAR PLAYLIST!
              _buildSection(
                'Genera playlists',
                _buildCreatePlaylist(),
              ),
              
              const SizedBox(height: 30),
              
              // 3. PLAYLISTS RECOMENDADAS
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
              onPressed: onSeeAllTap ?? () {}, // ¡Aquí conectamos el botón!
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
    // Si sigue cargando, mostramos la bolita
    if (_isLoadingData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: Color(0xFF9C7CFE)),
        )
      );
    }

    // Si no tienes artistas (cuenta nueva de Spotify)
    if (_topArtists.isEmpty) {
      return const Text(
        'Escucha más música en Spotify para ver a tus artistas favoritos aquí.',
        style: TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 13),
      );
    }

    // Si ya cargaron, los dibujamos
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _topArtists.length,
        itemBuilder: (context, index) {
          final artist = _topArtists[index];
          final name = artist['name'] ?? 'Artista';
          
          // Extraer la imagen real del artista
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
                    width: 70, // Ancho fijo para que el texto no se desborde
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // Si es muy largo pone "..."
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
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreatePlaylistScreen()),
        );
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
                image: AssetImage('assets/images/playlist1.png'), // Esto puede hacerse dinámico luego
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