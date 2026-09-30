import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_warmup/tone_synthesizer.dart';

void main() {
  test('ToneSynthesizer generates audible WAV samples', () {
    final bytes = ToneSynthesizer.generateTone(
      frequency: 440.0,
      durationSeconds: 0.5,
      volume: 0.85,
    );

    expect(bytes.length, greaterThan(44));
    final ByteData bd = ByteData.sublistView(bytes, 44);
    int maxVal = 0;
    for (int i = 0; i < bd.lengthInBytes; i += 2) {
      final sample = bd.getInt16(i, Endian.little).abs();
      if (sample > maxVal) maxVal = sample;
    }
    expect(maxVal, greaterThan(1000));
  });
}
