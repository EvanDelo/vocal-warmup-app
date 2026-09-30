import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import '../../models/music_theory.dart';
import 'audio_engine_interface.dart';

class AudioEngine implements AudioEngineBase {
  web.AudioContext? _audioContext;
  web.AudioBufferSourceNode? _currentSource;
  web.GainNode? _currentGain;
  final Map<int, web.AudioBuffer> _bufferCache = {};

  void _ensureContext() {
    _audioContext ??= web.AudioContext();
    if (_audioContext!.state == 'suspended') {
      _audioContext!.resume();
    }
  }

  web.AudioBuffer _getOrCreateBuffer(int midi) {
    web.AudioBuffer? buffer = _bufferCache[midi];
    if (buffer != null) return buffer;

    _ensureContext();
    final ctx = _audioContext!;
    final sampleRate = ctx.sampleRate.toInt();
    // 6 full seconds of acoustic piano decay ensures long sustained notes ring out fully
    const double bufferDuration = 6.0;
    final numSamples = (sampleRate * bufferDuration).round();

    buffer = ctx.createBuffer(1, numSamples, sampleRate.toDouble());
    final Float32List samples = Float32List(numSamples);

    final noteInfo = NoteInfo.fromMidi(midi);
    final frequency = noteInfo.frequency;

    // Acoustic piano harmonics
    const List<double> harmonicWeights = [
      1.00, // Fundamental
      0.68, // 2nd harmonic
      0.40, // 3rd harmonic
      0.24, // 4th harmonic
      0.14, // 5th harmonic
      0.08, // 6th harmonic
      0.04, // 7th harmonic
    ];

    final int numHarmonics = min(harmonicWeights.length, (18000 / frequency).floor());
    const double inharmonicity = 0.00025;
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

      final double pitchDamping = (frequency / 350.0).clamp(0.7, 2.2);
      decayRates[h - 1] = (1.1 + (0.4 * h) + (0.04 * h * h)) * pitchDamping;
    }

    final double norm = sumWeights > 0 ? (1.0 / sumWeights) : 1.0;
    final int attackSamples = (0.010 * sampleRate).round();
    final int releaseSamples = (0.050 * sampleRate).round();
    final int releaseStart = max(0, numSamples - releaseSamples);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;

      double strings = 0.0;
      for (int h = 0; h < numHarmonics; h++) {
        final double decay = exp(-decayRates[h] * t);
        final double str1 = sin(f1[h] * t);
        final double str2 = sin(f2[h] * t);
        strings += amps[h] * decay * (0.65 * str1 + 0.35 * str2);
      }

      double sample = strings * norm;

      // Cosine smooth attack: 0 blip
      if (i < attackSamples) {
        sample *= 0.5 * (1.0 - cos(pi * i / attackSamples));
      }

      // Smooth release at tail of 6s
      if (i >= releaseStart) {
        final double r = (i - releaseStart) / releaseSamples;
        sample *= 0.5 * (1.0 + cos(pi * r));
      }

      samples[i] = sample.clamp(-1.0, 1.0);
    }

    buffer.copyToChannel(samples.toJS, 0);

    _bufferCache[midi] = buffer;
    return buffer;
  }

  @override
  void playMidiNote(int midi, {double durationSeconds = 0.5, double volume = 0.9}) {
    _ensureContext();
    final ctx = _audioContext!;

    // Instantly stop previous note with 0ms latency
    if (_currentSource != null) {
      try {
        _currentGain?.gain.setValueAtTime(0.0001, ctx.currentTime);
        _currentSource?.stop();
        _currentSource?.disconnect();
      } catch (_) {}
      _currentSource = null;
    }

    final buffer = _getOrCreateBuffer(midi);
    final source = ctx.createBufferSource();
    source.buffer = buffer;

    final gainNode = ctx.createGain();
    gainNode.gain.setValueAtTime(volume, ctx.currentTime);

    // Fade cleanly to 0 at the exact duration calculated from BPM
    final stopTime = ctx.currentTime + durationSeconds;
    final fadeTime = min(0.03, durationSeconds * 0.2);
    gainNode.gain.setValueAtTime(volume, stopTime - fadeTime);
    gainNode.gain.linearRampToValueAtTime(0.0001, stopTime);

    source.connect(gainNode);
    gainNode.connect(ctx.destination);

    // Start with hardware audio sample accuracy
    source.start(ctx.currentTime);
    source.stop(stopTime + 0.01);

    _currentSource = source;
    _currentGain = gainNode;
  }

  @override
  void precacheMidiRange(int minMidi, int maxMidi) {
    _ensureContext();
    for (int m = minMidi; m <= maxMidi; m++) {
      if (!_bufferCache.containsKey(m)) {
        _getOrCreateBuffer(m);
      }
    }
  }

  @override
  void stop() {
    if (_currentSource != null && _audioContext != null) {
      try {
        _currentGain?.gain.setValueAtTime(0.0001, _audioContext!.currentTime);
        _currentSource?.stop();
        _currentSource?.disconnect();
      } catch (_) {}
      _currentSource = null;
    }
  }

  @override
  void dispose() {
    stop();
    _bufferCache.clear();
    _audioContext?.close();
  }
}
