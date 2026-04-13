import 'package:share_plus/share_plus.dart';

class ShareHelper {
  static Future<void> shareText(String text) async {
    try {
      await Share.share(text);
    } catch (_) {}
  }
}


