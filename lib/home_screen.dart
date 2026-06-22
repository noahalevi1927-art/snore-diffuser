import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'audio_service.dart';
import 'ha_service.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isListening = false;
  double _currentDb = 0;
  double _threshold = 70;
  int _triggerCount = 0;
  String _status = 'מוכן';
  String _lastTriggerTime = '';

  late AudioService _audioService;
  late HAService _haService;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _haService = HAService();
    _loadSettings();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _threshold = prefs.getDouble('threshold') ?? 70.0;
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _audioService.stop();
      setState(() {
        _isListening = false;
        _currentDb = 0;
        _status = 'מוכן';
      });
    } else {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('נדרשת הרשאה למיקרופון')),
          );
        }
        return;
      }

      setState(() {
        _isListening = true;
        _status = 'מאזין...';
      });

      _audioService.startListening((db) async {
        if (!mounted) return;
        setState(() {
          _currentDb = db;
        });

        if (db >= _threshold) {
          setState(() {
            _status = '😤 נחירה זוהתה!';
            _triggerCount++;
            _lastTriggerTime = _formattedTime();
          });
          await _haService.triggerWebhook();
          await Future.delayed(const Duration(seconds: 10));
          if (mounted && _isListening) {
            setState(() => _status = 'מאזין...');
          }
        }
      });
    }
  }

  String _formattedTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  Color _dbColor() {
    if (_currentDb < _threshold * 0.7) return Colors.green;
    if (_currentDb < _threshold * 0.9) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _audioService.stop();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          '💨 Snore Diffuser',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadSettings();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isListening ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: _isListening
                                ? [const Color(0xFF6B4EFF), const Color(0xFF3D1FBF)]
                                : [const Color(0xFF3D3D5C), const Color(0xFF1A1A2E)],
                          ),
                          boxShadow: _isListening
                              ? [BoxShadow(color: const Color(0xFF6B4EFF).withOpacity(0.5), blurRadius: 30, spreadRadius: 5)]
                              : [],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_off,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isListening ? 'לחץ לעצירה' : 'לחץ להתחלה',
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D2D4E)),
                ),
                child: Column(
                  children: [
                    Text(_status, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_currentDb / 100).clamp(0.0, 1.0),
                        minHeight: 16,
                        backgroundColor: const Color(0xFF2D2D4E),
                        valueColor: AlwaysStoppedAnimation<Color>(_dbColor()),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_currentDb.toStringAsFixed(1)} dB', style: TextStyle(color: _dbColor(), fontSize: 14)),
                        Text('סף: ${_threshold.toStringAsFixed(0)} dB', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _StatCard(icon: Icons.notifications_active, label: 'זיהויים', value: '$_triggerCount')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(icon: Icons.access_time, label: 'זיהוי אחרון', value: _lastTriggerTime.isEmpty ? '--:--' : _lastTriggerTime)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.bedtime, color: Color(0xFF6B4EFF), size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text('השאר את האפליקציה פתוחה בזמן שינה. הגדר "ללא הפרעה" על הטלפון.', style: TextStyle(color: Colors.white54, fontSize: 12))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D4E)),
      ),
