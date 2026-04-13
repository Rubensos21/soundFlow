import 'package:flutter/material.dart';
import 'dart:ui';
import 'favorites.dart';
import 'widgets/app_bottom_nav.dart';
import 'explore.dart';
import 'user_profile.dart';
import 'createPlaylist.dart';
import 'my_music_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 2});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // Por defecto el Home (índice 2)

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
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
    if (_selectedIndex == 0) {
      return const MyMusicScreen();
    }
    if (_selectedIndex == 1) {
      return const FavoritesScreen();
    }
    if (_selectedIndex == 3) {
      return const ExploreScreen();
    }
    if (_selectedIndex == 4) {
      return const UserProfileScreen();
    }
    // Home (índice 2) y resto por defecto
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hola Ruben!',
                style: TextStyle(
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

  Widget _buildSection(String title, Widget content) {
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
              onPressed: () {},
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
    final artists = [
      {'name': 'Twenty One Pilots', 'image': 'assets/images/artist1.png'},
      {'name': 'Travis Scott', 'image': 'assets/images/artist2.png'},
      {'name': 'Alvaro Diaz', 'image': 'assets/images/artist3.png'},
      {'name': 'NSQK', 'image': 'assets/images/artist4.png'},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: AssetImage(artists[index]['image']!),
                ),
                const SizedBox(height: 8),
                Text(
                  artists[index]['name']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
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