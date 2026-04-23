import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'artist_detail_screen.dart';

class TopArtistsScreen extends StatefulWidget {
  const TopArtistsScreen({super.key});

  @override
  State<TopArtistsScreen> createState() => _TopArtistsScreenState();
}

class _TopArtistsScreenState extends State<TopArtistsScreen> {
  static const _kAccent = Color(0xFF9C7CFE);
  static const _kBg     = Color(0xFF2D1B69);

  bool _isLoading = true;
  List<dynamic> _artists = [];

  @override
  void initState() {
    super.initState();
    _loadAllArtists();
  }

  Future<void> _loadAllArtists() async {
    try {
      final data = await ApiClient().getTopArtists(limit: 50);
      if (mounted) setState(() { _artists = data['items'] ?? []; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tus artistas favoritos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            fontSize: 18,
          ),
        ),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_artists.length} artistas',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontFamily: 'Poppins',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading ? _buildSkeletons() : _buildGrid(),
    );
  }

  // ── Skeletons mientras carga ─────────────────────────────────────────────
  Widget _buildSkeletons() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 10,
      ),
      itemCount: 12,
      itemBuilder: (_, __) => Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 10, width: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Grid de artistas ─────────────────────────────────────────────────────
  Widget _buildGrid() {
    if (_artists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'Escucha más música en Spotify\npara ver tus artistas aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 10,
      ),
      itemCount: _artists.length,
      itemBuilder: (context, index) {
        final artist   = _artists[index];
        final name     = artist['name']?.toString() ?? 'Artista';
        final images   = artist['images'] as List?;
        final imageUrl = images != null && images.isNotEmpty
            ? images.first['url'] as String?
            : null;

        // Los primeros 3 tienen un badge de ranking
        final isTop3 = index < 3;
        final rankColors = [
          const Color(0xFFFFD700), // oro
          const Color(0xFFC0C0C0), // plata
          const Color(0xFFCD7F32), // bronce
        ];

        // Tamaño fijo para garantizar círculo perfecto
        const double avatarSize = 90;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ArtistDetailScreen(artist: artist)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: avatarSize,
                height: avatarSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Anillo exterior (glow para top 3, sutil para el resto)
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isTop3
                              ? rankColors[index].withOpacity(0.7)
                              : _kAccent.withOpacity(0.25),
                          width: isTop3 ? 2.5 : 1.5,
                        ),
                        boxShadow: isTop3
                            ? [BoxShadow(
                                color: rankColors[index].withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )]
                            : null,
                      ),
                      child: ClipOval(
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholderAvatar(),
                              )
                            : _placeholderAvatar(),
                      ),
                    ),

                    // Badge de ranking (solo top 3)
                    if (isTop3)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: rankColors[index],
                            shape: BoxShape.circle,
                            border: Border.all(color: _kBg, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Text(
                name,
                style: TextStyle(
                  color: isTop3 ? Colors.white : Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  fontWeight: isTop3 ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _placeholderAvatar() {
    return Container(
      color: _kAccent.withOpacity(0.15),
      child: const Icon(Icons.person_rounded, color: Color(0xFF9C7CFE), size: 32),
    );
  }
}