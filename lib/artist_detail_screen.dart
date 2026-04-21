import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/api_client.dart'; // Importamos el cliente

class ArtistDetailScreen extends StatefulWidget {
  final Map<String, dynamic> artist;
  const ArtistDetailScreen({super.key, required this.artist});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  late Map<String, dynamic> _currentData;
  bool _isLoadingExtra = true;

  @override
  void initState() {
    super.initState();
    // Iniciamos con los datos resumidos que ya tenemos
    _currentData = widget.artist;
    // Y vamos a buscar los completos a escondidas
    _fetchFullArtistData();
  }

  Future<void> _fetchFullArtistData() async {
    final artistId = widget.artist['id'];
    if (artistId == null) {
      setState(() => _isLoadingExtra = false);
      return;
    }

    try {
      final api = ApiClient();
      final fullData = await api.getArtistDetails(artistId);
      if (mounted) {
        setState(() {
          _currentData = fullData; // ¡Reemplazamos con los datos completos!
          _isLoadingExtra = false;
        });
      }
    } catch (e) {
      print('Error obteniendo datos completos: $e');
      if (mounted) setState(() => _isLoadingExtra = false);
    }
  }

  Future<void> _openSpotify() async {
    final url = _currentData['external_urls']?['spotify'];
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Nombre
    final name = _currentData['name']?.toString() ?? 'Artista Desconocido';
    
    // 2. Extracción de Seguidores
    int followers = 0;
    if (_currentData.containsKey('followers') && _currentData['followers'] != null) {
      final fData = _currentData['followers'];
      if (fData is Map) followers = int.tryParse(fData['total']?.toString() ?? '0') ?? 0;
      else if (fData is int) followers = fData;
    }
    
    // 3. Extracción de Géneros
    List<String> genres = [];
    if (_currentData.containsKey('genres') && _currentData['genres'] != null) {
      final gData = _currentData['genres'];
      if (gData is List) genres = gData.map((e) => e.toString()).toList();
    }

    // 4. Imagen
    String? imageUrl;
    if (_currentData.containsKey('images') && _currentData['images'] != null) {
      final iData = _currentData['images'];
      if (iData is List && iData.isNotEmpty) imageUrl = iData.first['url']?.toString();
    }

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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Image
            Container(
              width: double.infinity,
              height: 350,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageUrl != null 
                    ? NetworkImage(imageUrl) 
                    : const AssetImage('assets/images/perfil.png') as ImageProvider,
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
                      const Color(0xFF2D1B69).withOpacity(0.5),
                      const Color(0xFF2D1B69),
                    ],
                  ),
                ),
              ),
            ),
            
            // Info Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Muestra cargando o los seguidores
                  _isLoadingExtra 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2)
                      )
                    : Text(
                        '${_formatNumber(followers)} seguidores',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                          fontFamily: 'Poppins',
                        ),
                      ),
                  
                  const SizedBox(height: 24),
                  
                  ElevatedButton.icon(
                    onPressed: _openSpotify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Abrir en Spotify', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Géneros', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins')),
                  ),
                  const SizedBox(height: 12),
                  
                  // Muestra cargando o los géneros
                  if (_isLoadingExtra)
                     const Align(
                       alignment: Alignment.centerLeft,
                       child: Text('Cargando etiquetas...', style: TextStyle(color: Colors.white70, fontFamily: 'Poppins')),
                     )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: genres.isEmpty 
                        ? [Chip(
                            label: const Text('Sin etiquetas', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                            backgroundColor: Colors.white.withOpacity(0.1),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          )]
                        : genres.map((g) => Chip(
                            label: Text(g.toUpperCase(), style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600)),
                            backgroundColor: const Color(0xFF9C7CFE).withOpacity(0.3),
                            side: const BorderSide(color: Color(0xFF9C7CFE), width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          )).toList(),
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}