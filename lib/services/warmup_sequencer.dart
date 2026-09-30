import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/music_theory.dart';
import 'audio_engine.dart';

class WarmupSequencer extends ChangeNotifier {
  final AudioEngine _audio = AudioEngine();

  bool _isPlaying = false;
  bool _isAscending = true;
  bool _autoReverse = true;

  int _bpm = 100;
  int _currentRootMidi = 48; // Default C3
  int? _activeNoteMidi;

  ExercisePattern _currentPattern = ExercisePattern.presets[0];
  VoiceRangePreset _currentRange = VoiceRangePreset.presets[0]; // Default Tenor
  Articulation _articulation = Articulation.legato;

  Timer? _sequenceTimer;
  int _patternStepIndex = 0;

  DateTime? _phraseStartTime;
  double _scheduledBeatProgress = 0.0;

  WarmupSequencer() {
    _currentRootMidi = effectiveMinRoot;
    _precacheRange();
  }

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isAscending => _isAscending;
  bool get autoReverse => _autoReverse;
  int get bpm => _bpm;
  int get currentRootMidi => _currentRootMidi;
  int? get activeNoteMidi => _activeNoteMidi;
  ExercisePattern get currentPattern => _currentPattern;
  VoiceRangePreset get currentRange => _currentRange;
  Articulation get articulation => _articulation;

  int get minMidi => _currentRange.minMidi;
  int get maxMidi => _currentRange.maxMidi;

  /// The highest root note we can transpose to so that the maximum sounding pitch in the pattern never exceeds maxMidi
  int get effectiveMaxRoot => max(_currentRange.minMidi, _currentRange.maxMidi - _currentPattern.maxInterval);
  int get effectiveMinRoot => _currentRange.minMidi;
  int get currentPeakSungMidi => _currentRootMidi + _currentPattern.maxInterval;

  NoteInfo get currentRootInfo => NoteInfo.fromMidi(_currentRootMidi);
  NoteInfo get currentPeakInfo => NoteInfo.fromMidi(currentPeakSungMidi);
  NoteInfo? get activeNoteInfo => _activeNoteMidi != null ? NoteInfo.fromMidi(_activeNoteMidi!) : null;

  void setBpm(int newBpm) {
    _bpm = newBpm.clamp(40, 240);
    notifyListeners();
  }

  void setArticulation(Articulation art) {
    _articulation = art;
    notifyListeners();
  }

  void setPattern(ExercisePattern pattern) {
    _currentPattern = pattern;
    _patternStepIndex = 0;
    _currentRootMidi = _currentRootMidi.clamp(effectiveMinRoot, effectiveMaxRoot);
    notifyListeners();
  }

  void setVoiceRange(VoiceRangePreset range) {
    _currentRange = range;
    _isAscending = true;
    _patternStepIndex = 0;
    _currentRootMidi = range.minMidi.clamp(effectiveMinRoot, effectiveMaxRoot);
    _precacheRange();
    notifyListeners();
  }

  void setCustomRange({required int minMidi, required int maxMidi, bool precache = false}) {
    final validMin = min(minMidi, maxMidi - 1);
    final validMax = max(minMidi + 1, maxMidi);
    _currentRange = _currentRange.copyWith(
      id: 'custom',
      name: 'Custom (${NoteInfo.fromMidi(validMin).name} - ${NoteInfo.fromMidi(validMax).name})',
      minMidi: validMin,
      maxMidi: validMax,
      isCustom: true,
    );
    _currentRootMidi = _currentRootMidi.clamp(effectiveMinRoot, effectiveMaxRoot);
    if (precache) {
      _precacheRange();
    }
    notifyListeners();
  }

  void finishCustomRange() {
    _precacheRange();
  }

  void setAutoReverse(bool value) {
    _autoReverse = value;
    notifyListeners();
  }

  void togglePlay() {
    if (_isPlaying) {
      stop();
    } else {
      start();
    }
  }

  void start() {
    _isPlaying = true;
    _patternStepIndex = 0;
    _phraseStartTime = DateTime.now();
    _scheduledBeatProgress = 0.0;
    notifyListeners();
    _playNextNoteInPattern();
  }

  void stop() {
    _isPlaying = false;
    _sequenceTimer?.cancel();
    _sequenceTimer = null;
    _phraseStartTime = null;
    _scheduledBeatProgress = 0.0;
    _activeNoteMidi = null;
    _patternStepIndex = 0;
    _audio.stop();
    notifyListeners();
  }

  void stepKey(int semitones) {
    _currentRootMidi = (_currentRootMidi + semitones).clamp(effectiveMinRoot, effectiveMaxRoot);
    _patternStepIndex = 0;
    notifyListeners();
    _audio.playMidiNote(_currentRootMidi, durationSeconds: 0.5);
  }

  void setKeyAndAudition(int targetMidi) {
    _currentRootMidi = targetMidi.clamp(effectiveMinRoot, effectiveMaxRoot);
    _patternStepIndex = 0;
    _activeNoteMidi = targetMidi;
    notifyListeners();
    _audio.playMidiNote(targetMidi, durationSeconds: 0.6);
    Timer(const Duration(milliseconds: 400), () {
      if (!_isPlaying && _activeNoteMidi == targetMidi) {
        _activeNoteMidi = null;
        notifyListeners();
      }
    });
  }

  void _precacheRange() {
    Future.microtask(() {
      _audio.precacheMidiRange(_currentRange.minMidi, _currentRange.maxMidi + 1);
    });
  }

  void _playNextNoteInPattern() {
    if (!_isPlaying) return;

    final intervals = _currentPattern.semitoneIntervals;
    final durations = _currentPattern.noteDurationsInBeats;

    if (_patternStepIndex < intervals.length) {
      final interval = intervals[_patternStepIndex];
      final beatDuration = durations[_patternStepIndex];
      final targetMidi = _currentRootMidi + interval;

      _activeNoteMidi = targetMidi;
      notifyListeners();

      final fullBeatSec = (60.0 / _bpm) * beatDuration;
      final articulateNoteDuration = fullBeatSec * _articulation.durationRatio;
      _audio.playMidiNote(targetMidi, durationSeconds: articulateNoteDuration);

      if (_articulation == Articulation.staccato) {
        final liftMs = (articulateNoteDuration * 1000).round();
        Timer(Duration(milliseconds: liftMs), () {
          if (_isPlaying && _activeNoteMidi == targetMidi) {
            _activeNoteMidi = null;
            notifyListeners();
          }
        });
      }

      _patternStepIndex++;
      _scheduledBeatProgress += beatDuration;

      final targetMs = (_scheduledBeatProgress * (60000.0 / _bpm)).round();
      final elapsedMs = DateTime.now().difference(_phraseStartTime!).inMilliseconds;
      final delayMs = max(0, targetMs - elapsedMs);

      _sequenceTimer = Timer(Duration(milliseconds: delayMs), _playNextNoteInPattern);
    } else {
      _activeNoteMidi = null;
      notifyListeners();

      const breathBeats = 2.0;
      _scheduledBeatProgress += breathBeats;

      final targetMs = (_scheduledBeatProgress * (60000.0 / _bpm)).round();
      final elapsedMs = DateTime.now().difference(_phraseStartTime!).inMilliseconds;
      final delayMs = max(0, targetMs - elapsedMs);

      _sequenceTimer = Timer(Duration(milliseconds: delayMs), _advanceKey);
    }
  }

  void _advanceKey() {
    if (!_isPlaying) return;

    if (_isAscending) {
      if (_currentRootMidi + 1 <= effectiveMaxRoot) {
        _currentRootMidi += 1;
      } else {
        if (_autoReverse) {
          _isAscending = false;
          _currentRootMidi = (_currentRootMidi - 1).clamp(effectiveMinRoot, effectiveMaxRoot);
        } else {
          stop();
          return;
        }
      }
    } else {
      if (_currentRootMidi - 1 >= effectiveMinRoot) {
        _currentRootMidi -= 1;
      } else {
        if (_autoReverse) {
          _isAscending = true;
          _currentRootMidi = (_currentRootMidi + 1).clamp(effectiveMinRoot, effectiveMaxRoot);
        } else {
          stop();
          return;
        }
      }
    }

    _patternStepIndex = 0;
    _phraseStartTime = DateTime.now();
    _scheduledBeatProgress = 0.0;

    notifyListeners();
    _playNextNoteInPattern();
  }

  @override
  void dispose() {
    stop();
    _audio.dispose();
    super.dispose();
  }
}
