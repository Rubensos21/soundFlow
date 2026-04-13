import 'package:flutter/foundation.dart';

import 'streaming_service.dart';

class AppleMusicService extends StreamingService {
  AppleMusicService() : super('apple');

  @override
  Future<List<Map<String, dynamic>>> getUserTopTracks({int limit = 50}) async {
    try {
      final response = await makeRequest('/me/top/tracks?limit=$limit');
      final items = response['items'] as List? ?? [];
      return items.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('Error obteniendo favoritos de Apple Music: $e');
      }
      return [];
    }
  }
}

