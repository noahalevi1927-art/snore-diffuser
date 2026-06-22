import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HAService {
  Future<void> triggerWebhook() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('webhook_url') ?? '';

    if (url.isEmpty) return;

    try {
      await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: '{"source": "snore_detected"}',
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Fail silently in POC
    }
  }
}
