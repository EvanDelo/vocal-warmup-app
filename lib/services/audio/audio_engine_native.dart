import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import '../../models/music_theory.dart';
import '../../tone_synthesizer.dart';
import 'audio_engine_interface.dart';

class AudioEngine implements AudioEngineBase {
  final AudioPlayer _player = AudioPlayer();
  final Map<int, Source> _sourceCache = {};

  AudioEngine() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  Source _getOrCreateSource(int midi, double durationSeconds, double volume) {
    Source? source = _sourceCache[midi];
    if (source == null) {
      final noteInfo = NoteInfo.fromMidi(midi);
      final Uint8List bytes = ToneSynthesizer.generateTone(
        frequency: noteInfo.frequency,
        durationSeconds: durationSeconds,
        volume: volume,
      );
      source = BytesSource(bytes);
      _sourceCache[midi] = source;
    }
    return source;
  }

  @override
  void playMidiNote(int midi, {double durationSeconds = 0.5, double volume = 0.9}) {
    final source = _getOrCreateSource(midi, durationSeconds, volume);
    // Fire immediately without waiting on stop promise to ensure zero delay
    _player.play(source);
  }

  @override
  void precacheMidiRange(int minMidi, int maxMidi) {
    for (int m = minMidi; m <= maxMidi; m++) {
      if (!_sourceCache.containsKey(m)) {
        _getOrCreateSource(m, 0.6, 0.9);
      }
    }
  }

  @override
  void stop() {
    _player.stop();
  }

  @override
  void dispose() {
    _player.dispose();
    _sourceCache.clear();
  }
}
