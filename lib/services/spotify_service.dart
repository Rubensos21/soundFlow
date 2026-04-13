import 'package:flutter/foundation.dart';
import 'streaming_service.dart';

class SpotifyService extends StreamingService {
  SpotifyService() : super('spotify');

  Future<List<Map<String, dynamic>>> getUserTopArtists({
    int limit = 50,
    String timeRange = 'medium_term',
  }) async {
    try {
      final response =
          await makeRequest('/me/top/artists?limit=$limit&time_range=$timeRange');
      final items = response['items'] as List? ?? [];
      return items.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('Error obteniendo artistas favoritos: $e');
      }
      return [];
    }
  }

  Future<Map<String, dynamic>> getPlaylistDetails(String playlistId) async {
    try {
      return await makeRequest('/playlists/$playlistId');
    } catch (e) {
      if (kDebugMode) {
        print('Error obteniendo detalles de playlist: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> search(
    String query, {
    String type = 'track,artist,album',
    int limit = 20,
  }) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      return await makeRequest('/search?q=$encodedQuery&type=$type&limit=$limit');
    } catch (e) {
      if (kDebugMode) {
        print('Error en búsqueda: $e');
      }
      rethrow;
    }
  }
}

