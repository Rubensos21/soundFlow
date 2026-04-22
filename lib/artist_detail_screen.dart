import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/api_client.dart';

class ArtistDetailScreen extends StatefulWidget {
  final Map<String, dynamic> artist;
  const ArtistDetailScreen({super.key, required this.artist});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  late Map<String, dynamic> _currentData;
  bool _isLoadingExtra = true;
  String? _fetchError;

  List<dynamic> _topTracks = [];
  bool _isLoadingTracks = true;

  @override
  void initState() {
    super.initState();
    _currentData = widget.artist;
    _fetchFullArtistData();
    _fetchTopTracks();
  }

  Future<void> _fetchFullArtistData() async {
    final artistId = widget.artist['id'];
    if (artistId == null) {
      if (mounted) setState(() => _isLoadingExtra = false);
      return;
    }
    try {
      final fullData = await ApiClient().getArtistDetails(artistId);
      if (mounted) {
        setState(() {
          _currentData = {..._currentData, ...fullData};
          _isLoadingExtra = false;
          _fetchError = null;
        });
      }
    } catch (e) {
      debugPrint('Error en _fetchFullArtistData: $e');
      if (mounted) setState(() { _isLoadingExtra = false; _fetchError = e.toString(); });
    }
  }

  Future<void> _fetchTopTracks() async {
    final artistId = widget.artist['id'];
    if (artistId == null) {
      if (mounted) setState(() => _isLoadingTracks = false);
      return;
    }
    try {
      final data = await ApiClient().getArtistTopTracks(artistId);
      if (mounted) {
        setState(() {
          _topTracks = data['tracks'] ?? [];
          _isLoadingTracks = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando top tracks: $e');
      if (mounted) setState(() => _isLoadingTracks = false);
    }
  }

  Future<void> _openSpotify() async {
    final url = _currentData['external_urls']?['spotify'];
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  int _parseFollowers() {
    try {
      final f = _currentData['followers'];
      if (f == null) return -1;
      if (f is Map) return int.parse(f['total'].toString());
      return int.parse(f.toString());
    } catch (_) { return -1; }
  }

  List<String> _parseGenres() {
    try {
      final g = _currentData['genres'];
      if (g == null || g is! List) return [];
      return List<String>.from(g.map((e) => e.toString()));
    } catch (_) { return []; }
  }

  String? _parseImageUrl() {
    final images = _currentData['images'];
    if (images is List && images.isNotEmpty) {
      return images[0]['url']?.toString();
    }
    return null;
  }

  String _formatNumber(int n) {
    if (n < 0) return 'N/D';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final name = _currentData['name']?.toString() ?? 'Artista Desconocido';
    final followers = _parseFollowers();
    final genres = _parseGenres();
    final imageUrl = _parseImageUrl();

    return Scaffold(
      backgroundColor: const Color(0xFF2D1B69),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_fetchError != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.orangeAccent),
              onPressed: () {
                setState(() { _isLoadingExtra = true; _fetchError = null; });
                _fetchFullArtistData();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero Image ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 320,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    Image.network(imageUrl, fit: BoxFit.cover)
                  else
                    Image.asset('assets/images/perfil.png', fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF2D1B69).withOpacity(0.6),
                          const Color(0xFF2D1B69),
                        ],
                        stops: const [0.3, 0.75, 1.0],
                      ),
                    ),
                  ),
                  // Nombre sobre el hero
                  Positioned(
                    bottom: 16,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        if (_isLoadingExtra)
                          const SizedBox(
                            height: 16, width: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white54, strokeWidth: 2))
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  color: Colors.white54, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                followers >= 0
                                    ? '${_formatNumber(followers)} oyentes mensuales'
                                    : '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white54,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Botón Spotify ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openSpotify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: const Text('Abrir en Spotify',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Géneros ──────────────────────────────────────────────
                  if (!_isLoadingExtra && genres.isNotEmpty) ...[
                    const Text('Géneros',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins')),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: genres.map((g) => Chip(
                        label: Text(g.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        backgroundColor:
                            const Color(0xFF9C7CFE).withOpacity(0.25),
                        side: const BorderSide(color: Color(0xFF9C7CFE), width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Top Tracks ───────────────────────────────────────────
                  Row(
                    children: [
                      const Text('Populares',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Poppins')),
                      if (_isLoadingTracks) ...[
                        const SizedBox(width: 10),
                        const SizedBox(
                          height: 14, width: 14,
                          child: CircularProgressIndicator(
                              color: Colors.white38, strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                  
                  // 1. REDUCIMOS ESTE ESPACIO (antes era 14, lo bajamos a 4 o 0)
                  const SizedBox(height: 4),

                  if (!_isLoadingTracks)
                    _topTracks.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No se encontraron canciones populares.',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontFamily: 'Poppins',
                                  fontSize: 13),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            //2. ELIMINAMOS EL MARGEN OCULTO DE LA LISTA
                            padding: EdgeInsets.zero, 
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _topTracks.length > 5 ? 5 : _topTracks.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, i) {
                              // ... (todo el código de adentro se queda igual)
                              final track =
                                  _topTracks[i] as Map<String, dynamic>;
                              final trackName =
                                  track['name']?.toString() ?? 'Desconocido';
                              final playcount = int.tryParse(
                                      track['playcount']?.toString() ?? '0') ??
                                  0;
                              final trackImageUrl =
                                  track['image_url']?.toString();
                              final isTop3 = i < 3;

                              return _TrackTile(
                                index: i + 1,
                                name: trackName,
                                playcount: playcount,
                                imageUrl: trackImageUrl,
                                isTop3: isTop3,
                                formatNumber: _formatNumber,
                              );
                            },
                          ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Track Tile ───────────────────────────────────────────────────────────────

class _TrackTile extends StatelessWidget {
  final int index;
  final String name;
  final int playcount;
  final String? imageUrl;
  final bool isTop3;
  final String Function(int) formatNumber;

  const _TrackTile({
    required this.index,
    required this.name,
    required this.playcount,
    required this.isTop3,
    required this.formatNumber,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isTop3
            ? const Color(0xFF9C7CFE).withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop3
              ? const Color(0xFF9C7CFE).withOpacity(0.25)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          // Número
          SizedBox(
            width: 26,
            child: Text(
              '$index',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: isTop3 ? 16 : 13,
                color: isTop3
                    ? const Color(0xFF9C7CFE)
                    : Colors.white.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Portada
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImage(),
                  )
                : _placeholderImage(),
          ),
          const SizedBox(width: 12),

          // Nombre y plays
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.headphones_outlined,
                        size: 11,
                        color: Colors.white.withOpacity(0.35)),
                    const SizedBox(width: 3),
                    Text(
                      '${formatNumber(playcount)} reproducciones',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontFamily: 'Poppins',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Ícono play (decorativo, simula Spotify)
          Icon(
            Icons.play_circle_outline_rounded,
            color: Colors.white.withOpacity(0.2),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFF9C7CFE).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note_rounded,
          color: Color(0xFF9C7CFE), size: 20),
    );
  }
}