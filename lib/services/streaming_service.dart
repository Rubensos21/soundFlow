import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'api_client.dart';

abstract class StreamingService {
  StreamingService(this.platform);

  final String platform;
  final ApiClient _apiClient = ApiClient();

  String get _basePath => '/$platform';

  /// Verificar si el usuario tiene la plataforma conectada
  Future<bool> hasConnection() async {
    try {
      final accounts = await _apiClient.getLinkedAccounts();
      final linkedAccounts =
          List<Map<String, dynamic>>.from(accounts['accounts'] ?? []);
      return linkedAccounts.any(
        (acc) => acc['platform'] == platform && acc['linked'] == true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error verificando conexión $platform: $e');
      }
      return false;
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    return makeRequest('/me');
  }

  Future<List<Map<String, dynamic>>> getUserPlaylists({int limit = 50}) async {
    final response = await makeRequest('/me/playlists?limit=$limit');
    final items = response['items'] as List? ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getUserTopTracks({int limit = 50}) async {
    final response = await makeRequest('/me/top/tracks?limit=$limit');
    final items = response['items'] as List? ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getRecentlyPlayed({int limit = 50}) async {
    final response =
        await makeRequest('/me/player/recently-played?limit=$limit');
    final items = response['items'] as List? ?? [];
    return items.map((item) {
      if (item.containsKey('track')) {
        final track = Map<String, dynamic>.from(item['track'] as Map);
        if (item['played_at'] != null) {
          track['played_at'] = item['played_at'];
        }
        return track;
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getSavedTracks({int limit = 50}) async {
    final response = await makeRequest('/me/tracks?limit=$limit');
    final items = response['items'] as List? ?? [];
    return items.map((item) {
      if (item.containsKey('track')) {
        return Map<String, dynamic>.from(item['track'] as Map);
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  @protected
  Future<Map<String, dynamic>> makeRequest(String endpoint) async {
    try {
      final uri = Uri.parse('${_apiClient.baseUrl}$_basePath$endpoint');
      if (kDebugMode) {
        print('StreamingService($platform): GET $uri');
      }
      final response = await http.get(uri);

      if (kDebugMode) {
        print('StreamingService($platform): Status ${response.statusCode}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception(
          'No autorizado. Por favor, vuelve a conectar tu cuenta de ${platformDisplayName(platform)}.',
        );
      } else {
        throw Exception(
          'Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('StreamingService($platform): Error - $e');
      }
      rethrow;
    }
  }

  static String platformDisplayName(String platform) {
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
}

