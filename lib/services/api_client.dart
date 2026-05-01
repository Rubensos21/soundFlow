import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiClient {
  ApiClient({String? baseUrl})
      : _baseUrl = baseUrl ?? _getDefaultBaseUrl() {
    if (kDebugMode) {
      print('ApiClient inicializado con baseUrl: $_baseUrl');
    }
  }

  final String _baseUrl;

  static String _getDefaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    } else {
      return 'http://127.0.0.1:8000';
    }
  }

  String get baseUrl => _baseUrl;

  String getAuthUrlForBrowser(String platform) {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/auth/$platform';
    }
    return '$_baseUrl/auth/$platform';
  }

  // ── Helper: imprime strings largos sin truncar ──────────────────────────
  void _printFull(String label, String text) {
    const chunk = 900;
    print('── $label (${text.length} chars) ──');
    for (var i = 0; i < text.length; i += chunk) {
      final end = (i + chunk) < text.length ? (i + chunk) : text.length;
      print(text.substring(i, end));
    }
    print('── fin $label ──');
  }

  // ── Helper: parsea JSON y lo imprime completo en debug ──────────────────
  Map<String, dynamic> _decodeAndLog(String label, http.Response res) {
    if (kDebugMode) {
      print('\n[ApiClient] $label → status: ${res.statusCode}');
      _printFull('BODY', res.body);
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generatePlaylistFromPrompt(String prompt) async {
    final uri = Uri.parse('$_baseUrl/api/generate-playlist/prompt');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': prompt}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> generatePlaylistFromFacial(XFile imageFile) async {
    final uri = Uri.parse('$_baseUrl/api/generate-playlist/facial');
    final request = http.MultipartRequest('POST', uri);
    final bytes = await imageFile.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: imageFile.name));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  String getAuthUrl(String platform) => getAuthUrlForBrowser(platform);

  Future<Map<String, dynamic>> getLinkedAccounts() async {
    final uri = Uri.parse('$_baseUrl/me/linked-accounts');
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  Future<bool> checkConnection() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> handleAuthCallback(
      String platform, String code, String state) async {
    final uri = Uri.parse('$_baseUrl/auth/$platform/callback').replace(
      queryParameters: {'code': code, 'state': state},
    );
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> getGeneratedPlaylists() async {
    final uri = Uri.parse('$_baseUrl/api/playlists/generated');
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> getGeneratedPlaylistDetail(int playlistId) async {
    final uri = Uri.parse('$_baseUrl/api/playlists/generated/$playlistId');
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> deleteGeneratedPlaylist(int playlistId) async {
    final uri = Uri.parse('$_baseUrl/api/playlists/generated/$playlistId');
    final res = await http.delete(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> getSpotifyProfile() async {
    final uri = Uri.parse('$_baseUrl/spotify/me');
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Error obteniendo perfil de Spotify: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> getTopArtists({int limit = 4}) async {
    final uri = Uri.parse('$_baseUrl/spotify/me/top/artists?limit=$limit');
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Error obteniendo top artistas: ${res.statusCode}');
  }

  /// Obtiene el expediente completo del artista desde Spotify.
  Future<Map<String, dynamic>> getArtistDetails(String artistId) async {
    final uri = Uri.parse('$_baseUrl/spotify/artists/$artistId');

    if (kDebugMode) {
      print('\n[getArtistDetails] GET $uri');
    }

    final res = await http.get(uri);

    if (kDebugMode) {
      _printFull('getArtistDetails BODY (status=${res.statusCode})', res.body);
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

      if (data.containsKey('error') && !data.containsKey('id')) {
        final errInfo = data['error'];
        throw Exception('Spotify devolvió error: $errInfo');
      }

      if (kDebugMode) {
        print('[getArtistDetails] Claves recibidas: ${data.keys.toList()}');
        print('[getArtistDetails] followers: ${data['followers']}');
        print('[getArtistDetails] genres: ${data['genres']}');
      }

      return data;
    }

    throw Exception('Error ${res.statusCode} obteniendo artista $artistId: ${res.body}');
  }

  Future<Map<String, dynamic>> getArtistUserPlaylists(String artistId) async {
    final uri = Uri.parse('$_baseUrl/spotify/artists/$artistId/user-playlists');
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  // ── NUEVO: Obtener las canciones más populares del artista ──
  Future<Map<String, dynamic>> getArtistTopTracks(String artistId) async {
    final uri = Uri.parse('$_baseUrl/spotify/artists/$artistId/top-tracks');
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Error obteniendo top tracks del artista: ${res.statusCode}');
  }
  
}