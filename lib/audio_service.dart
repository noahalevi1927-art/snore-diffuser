import 'dart:async';
import 'package:noise_meter/noise_meter.dart';

class AudioService {
  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _subscription;

  void startListening(Function(double db) onReading) {
    _noiseMeter = NoiseMeter();
    _subscription = _noiseMeter!.noise.listen(
      (NoiseReading reading) {
        final db = reading.meanDecibel;
        if (db > 0 && db < 120) {
          onReading(db);
        }
      },
      onError: (error) {
        // Ignore errors silently in POC
      },
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _noiseMeter = null;
  }
}
