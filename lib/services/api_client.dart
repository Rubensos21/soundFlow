import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiClient {
  ApiClient({String? baseUrl}) 
      : _baseUrl = baseUrl ?? _getDefaultBaseUrl() {
    // Debug: mostrar la URL base que se está usando
    if (kDebugMode) {
      print('ApiClient inicializado con baseUrl: $_baseUrl');
    }
  }

  final String _baseUrl;
  
  // Método para obtener la URL base por defecto según la plataforma
  static String _getDefaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      // Para emulador Android: usar 10.0.2.2
      // Para dispositivo Android real: cambiar a la IP de tu PC (ej: 192.168.1.X)
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // Para simulador iOS: usar localhost
      // Para dispositivo iOS real: cambiar a la IP de tu PC
      return 'http://localhost:8000';
    } else {
      // Windows, macOS, Linux desktop
      return 'http://127.0.0.1:8000';
    }
  }
  
  // Método para obtener la URL base actual
  String get baseUrl => _baseUrl;
  
  // Método para obtener la URL de autenticación (puede ser diferente para navegadores)
  String getAuthUrlForBrowser(String platform) {
    // Si estamos en Android, el navegador del emulador también necesita usar 10.0.2.2
    // PERO si el navegador se abre en el host, necesita localhost
    // Para emulador: usamos la IP del host en la red local
    if (!kIsWeb && Platform.isAndroid) {
      // Aquí deberías usar la IP real de tu PC en la red local
      // Por ejemplo: http://192.168.1.100:8000
      // Por ahora, usamos 10.0.2.2 y esperamos que funcione
      return 'http://10.0.2.2:8000/auth/$platform';
    }
    return '$_baseUrl/auth/$platform';
  }

  Future<Map<String, dynamic>> generatePlaylistFromPrompt(String prompt) async {
    final uri = Uri.parse('$_baseUrl/api/generate-playlist/prompt');
    if (kDebugMode) {
      print('ApiClient: Enviando POST a $uri');
    }
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': prompt}),
    );
    if (kDebugMode) {
      print('ApiClient: Respuesta recibida - Status: ${res.statusCode}');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> generatePlaylistFromFacial(XFile imageFile) async {
    final uri = Uri.parse('$_baseUrl/api/generate-playlist/facial');
    final request = http.MultipartRequest('POST', uri);
    
    final bytes = await imageFile.readAsBytes();
    final multipartFile = http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: imageFile.name,
    );
    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  String getAuthUrl(String platform) {
    return getAuthUrlForBrowser(platform);
  }

  Future<Map<String, dynamic>> getLinkedAccounts() async {
    final uri = Uri.parse('$_baseUrl/me/linked-accounts');
    if (kDebugMode) {
      print('ApiClient: Enviando GET a $uri');
    }
    final res = await http.get(uri);
    if (kDebugMode) {
      print('ApiClient: Respuesta recibida - Status: ${res.statusCode}');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }
  
  // Método de prueba para verificar conexión
  Future<bool> checkConnection() async {
    try {
      final uri = Uri.parse('$_baseUrl/health');
      if (kDebugMode) {
        print('ApiClient: Verificando conexión con $uri');
      }
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (kDebugMode) {
        print('ApiClient: Conexión OK - Status: ${res.statusCode}');
      }
      return res.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('ApiClient: Error de conexión - $e');
      }
      return false;
    }
  }

  Future<Map<String, dynamic>> handleAuthCallback(String platform, String code, String state) async {
    final uri = Uri.parse('$_baseUrl/auth/$platform/callback').replace(
      queryParameters: {'code': code, 'state': state},
    );
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  // Obtener playlists generadas por IA
  Future<Map<String, dynamic>> getGeneratedPlaylists() async {
    final uri = Uri.parse('$_baseUrl/api/playlists/generated');
    if (kDebugMode) {
      print('ApiClient: Obteniendo playlists generadas desde $uri');
    }
    final res = await http.get(uri);
    if (kDebugMode) {
      print('ApiClient: Respuesta - Status: ${res.statusCode}');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  // Obtener detalles de una playlist generada
  Future<Map<String, dynamic>> getGeneratedPlaylistDetail(int playlistId) async {
    final uri = Uri.parse('$_baseUrl/api/playlists/generated/$playlistId');
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  // Eliminar una playlist generada
  Future<Map<String, dynamic>> deleteGeneratedPlaylist(int playlistId) async {
    final uri = Uri.parse('$_baseUrl/api/playlists/generated/$playlistId');
    final res = await http.delete(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }
}


