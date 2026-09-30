import 'dart:math';
import 'dart:typed_data';

/// Generates warm, clean acoustic piano pitch reference tones in memory.
/// Smooth phase-aligned sine harmonics with cosine-easing attack (zero blips, clicks, or DC offset).
class ToneSynthesizer {
  static const int sampleRate = 44100;

  static Uint8List generateTone({
    required double frequency,
    required double durationSeconds,
    double volume = 0.90,
  }) {
    final int numSamples = (sampleRate * durationSeconds).round();
    final int byteLength = numSamples * 2;

    final ByteData byteData = ByteData(44 + byteLength);

    // --- RIFF Header ---
    byteData.setUint8(0, 0x52); // "R"
    byteData.setUint8(1, 0x49); // "I"
    byteData.setUint8(2, 0x46); // "F"
    byteData.setUint8(3, 0x46); // "F"
    byteData.setUint32(4, 36 + byteLength, Endian.little);
    byteData.setUint8(8, 0x57);  // "W"
    byteData.setUint8(9, 0x41);  // "A"
    byteData.setUint8(10, 0x56); // "V"
    byteData.setUint8(11, 0x45); // "E"

    // --- "fmt " Subchunk ---
    byteData.setUint8(12, 0x66);
    byteData.setUint8(13, 0x6D);
    byteData.setUint8(14, 0x74);
    byteData.setUint8(15, 0x20);
    byteData.setUint32(16, 16, Endian.little); // PCM
    byteData.setUint16(20, 1, Endian.little);  // Mono
    byteData.setUint16(22, 1, Endian.little);  // 1 Channel
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);  // Block align
    byteData.setUint16(34, 16, Endian.little); // 16-bit

    // --- "data" Subchunk ---
    byteData.setUint8(36, 0x64); // "d"
    byteData.setUint8(37, 0x61); // "a"
    byteData.setUint8(38, 0x74); // "t"
    byteData.setUint8(39, 0x61); // "a"
    byteData.setUint32(40, byteLength, Endian.little);

    // Warm piano harmonic balance
    const List<double> harmonicWeights = [
      1.00, // Fundamental (1st)
      0.68, // 2nd harmonic (octave)
      0.40, // 3rd harmonic (octave + 5th)
      0.24, // 4th harmonic
      0.14, // 5th harmonic
      0.08, // 6th harmonic
      0.04, // 7th harmonic
    ];

    final int numHarmonics = min(harmonicWeights.length, (18000 / frequency).floor());

    // Inharmonicity factor (subtle string stiffness)
    const double inharmonicity = 0.00025;
    // Unison detuning for gentle acoustic chorus
    const double unisonDetuneHz = 0.30;

    final List<double> f1 = List.filled(numHarmonics, 0.0);
    final List<double> f2 = List.filled(numHarmonics, 0.0);
    final List<double> decayRates = List.filled(numHarmonics, 0.0);
    final List<double> amps = List.filled(numHarmonics, 0.0);

    double sumWeights = 0.0;
    for (int h = 1; h <= numHarmonics; h++) {
      final double stretch = sqrt(1.0 + inharmonicity * h * h);
      final double baseFreq = frequency * h * stretch;

      f1[h - 1] = 2.0 * pi * baseFreq;
      f2[h - 1] = 2.0 * pi * (baseFreq + unisonDetuneHz);

      final double w = harmonicWeights[h - 1];
      amps[h - 1] = w;
      sumWeights += w;

      // Pitch-dependent damping
      final double pitchDamping = (frequency / 350.0).clamp(0.7, 2.2);
      decayRates[h - 1] = (1.1 + (0.4 * h) + (0.04 * h * h)) * pitchDamping;
    }

    final double norm = sumWeights > 0 ? (1.0 / sumWeights) : 1.0;

    // Smooth Hann window attack (10ms): zero derivative at t=0 eliminates any start blip/click
    final int attackSamples = (0.010 * sampleRate).round();
    // Smooth release (30ms)
    final int releaseSamples = (0.030 * sampleRate).round();
    final int releaseStart = max(0, numSamples - releaseSamples);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;

      // Sum of acoustic piano string harmonics (all start at sin(0) = 0)
      double strings = 0.0;
      for (int h = 0; h < numHarmonics; h++) {
        final double decay = exp(-decayRates[h] * t);
        final double str1 = sin(f1[h] * t);
        final double str2 = sin(f2[h] * t);
        strings += amps[h] * decay * (0.65 * str1 + 0.35 * str2);
      }

      double sample = strings * norm;

      // 1. Hann/Cosine Attack: 0.5 * (1 - cos(pi * i / attackSamples))
      // Perfectly smooth ramp from exactly 0.0 without any discontinuity or click
      if (i < attackSamples) {
        final double ramp = 0.5 * (1.0 - cos(pi * i / attackSamples));
        sample *= ramp;
      }

      // 2. Smooth Release Ramp at end of duration
      if (i >= releaseStart) {
        final double r = (i - releaseStart) / releaseSamples;
        final double ramp = 0.5 * (1.0 + cos(pi * r));
        sample *= ramp;
      }

      final double clamped = (sample * volume).clamp(-1.0, 1.0);
      final int sample16 = (clamped * 28000.0).round();

      byteData.setInt16(44 + i * 2, sample16, Endian.little);
    }

    return byteData.buffer.asUint8List();
  }
}
