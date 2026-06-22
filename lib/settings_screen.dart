import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  double _threshold = 70;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _threshold = prefs.getDouble('threshold') ?? 70.0;
      _urlController.text = prefs.getString('webhook_url') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('threshold', _threshold);
    await prefs.setString('webhook_url', _urlController.text.trim());
    setState(() => _saved = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('הגדרות', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('סף עוצמת קול (dB)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D2D4E)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('שקט', style: TextStyle(color: Colors.white54)),
                      Text('${_threshold.toStringAsFixed(0)} dB', style: const TextStyle(color: Color(0xFF6B4EFF), fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('רועש', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                  Slider(
                    value: _threshold,
                    min: 40,
                    max: 100,
                    divisions: 60,
                    activeColor: const Color(0xFF6B4EFF),
                    inactiveColor: const Color(0xFF2D2D4E),
                    onChanged: (v) => setState(() => _threshold = v),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('40', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      Text('70 (ברירת מחדל)', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      Text('100', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
