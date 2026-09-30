import 'dart:math';

class NoteInfo {
  final int midi;
  final String name;
  final double frequency;

  const NoteInfo({
    required this.midi,
    required this.name,
    required this.frequency,
  });

  static const List<String> _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  static NoteInfo fromMidi(int midi) {
    final noteIndex = midi % 12;
    final octave = (midi ~/ 12) - 1;
    final name = '${_noteNames[noteIndex]}$octave';
    final frequency = 440.0 * pow(2.0, (midi - 69) / 12.0);
    return NoteInfo(midi: midi, name: name, frequency: frequency);
  }
}

enum Articulation {
  legato('Legato', 'Smooth & Connected', 0.95),
  staccato('Staccato', 'Crisp & Detached', 0.45);

  final String label;
  final String description;
  final double durationRatio;

  const Articulation(this.label, this.description, this.durationRatio);
}

class ExercisePattern {
  final String id;
  final String name;
  final String description;
  final List<int> semitoneIntervals; // Intervals relative to root note
  final List<double> noteDurationsInBeats; // Duration in beats for each note

  const ExercisePattern({
    required this.id,
    required this.name,
    required this.description,
    required this.semitoneIntervals,
    required this.noteDurationsInBeats,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExercisePattern && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  int get maxInterval => semitoneIntervals.isEmpty ? 0 : semitoneIntervals.reduce(max);
  int get minInterval => semitoneIntervals.isEmpty ? 0 : semitoneIntervals.reduce(min);

  static const List<ExercisePattern> presets = [
    ExercisePattern(
      id: '5_tone_scale',
      name: '5-Tone Scale',
      description: '1 - 2 - 3 - 4 - 5 - 4 - 3 - 2 - 1',
      semitoneIntervals: [0, 2, 4, 5, 7, 5, 4, 2, 0],
      noteDurationsInBeats: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0],
    ),
    ExercisePattern(
      id: 'octave_repeat',
      name: 'Octave Repeat',
      description: '1 - 3 - 5 - 8 - 8 - 8 - 8 - 5 - 3 - 1',
      semitoneIntervals: [0, 4, 7, 12, 12, 12, 12, 7, 4, 0],
      noteDurationsInBeats: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0],
    ),
    ExercisePattern(
      id: 'octave_repeat_sustain_top',
      name: 'Octave Repeat (Sustained Top)',
      description: '1 - 3 - 5 - 8 - 8 - 8 - 8s - 5 - 3 - 1',
      semitoneIntervals: [0, 4, 7, 12, 12, 12, 12, 7, 4, 0],
      noteDurationsInBeats: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 4.0, 1.0, 1.0, 2.0],
    ),
    ExercisePattern(
      id: 'octave_repeat_descending',
      name: 'Octave Repeat Descending',
      description: '8 - 8 - 8 - 8 - 5 - 3 - 1',
      semitoneIntervals: [12, 12, 12, 12, 7, 4, 0],
      noteDurationsInBeats: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0],
    ),
    ExercisePattern(
      id: 'octave_and_a_half',
      name: 'Octave and a Half',
      description: '1 - 3 - 5 - 8 - 10 - 12 - 11 - 9 - 7 - 5 - 4 - 2 - 1',
      semitoneIntervals: [0, 4, 7, 12, 16, 19, 17, 14, 11, 7, 5, 2, 0],
      noteDurationsInBeats: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0],
    ),
    ExercisePattern(
      id: 'major_triad_arpeggio',
      name: 'Major Arpeggio (Octave)',
      description: '1 - 3 - 5 - 8 - 5 - 3 - 1',
      semitoneIntervals: [0, 4, 7, 12, 7, 4, 0],
      noteDurationsInBeats: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0],
    ),
    ExercisePattern(
      id: 'octave_jump',
      name: 'Octave Jump',
      description: '1 - 8 - 1',
      semitoneIntervals: [0, 12, 0],
      noteDurationsInBeats: [1.0, 2.0, 2.0],
    ),
    ExercisePattern(
      id: 'descending_5_tone',
      name: 'Descending 5-Tone',
      description: '5 - 4 - 3 - 2 - 1',
      semitoneIntervals: [7, 5, 4, 2, 0],
      noteDurationsInBeats: [1.0, 1.0, 1.0, 1.0, 2.0],
    ),
    ExercisePattern(
      id: '3_tone_step',
      name: '3-Tone Step',
      description: '1 - 2 - 3 - 2 - 1',
      semitoneIntervals: [0, 2, 4, 2, 0],
      noteDurationsInBeats: [1.0, 1.0, 1.0, 1.0, 2.0],
    ),
  ];
}

class VoiceRangePreset {
  final String id;
  final String name;
  final int minMidi; // Starting root note
  final int maxMidi; // Top root note to transpose up to
  final bool isCustom;

  const VoiceRangePreset({
    required this.id,
    required this.name,
    required this.minMidi,
    required this.maxMidi,
    this.isCustom = false,
  });

  VoiceRangePreset copyWith({
    String? id,
    String? name,
    int? minMidi,
    int? maxMidi,
    bool? isCustom,
  }) {
    return VoiceRangePreset(
      id: id ?? this.id,
      name: name ?? this.name,
      minMidi: minMidi ?? this.minMidi,
      maxMidi: maxMidi ?? this.maxMidi,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceRangePreset && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  static const List<VoiceRangePreset> presets = [
    VoiceRangePreset(id: 'tenor', name: 'Tenor (C3 - C5)', minMidi: 48, maxMidi: 72),
    VoiceRangePreset(id: 'baritone', name: 'Baritone (A2 - A4)', minMidi: 45, maxMidi: 69),
    VoiceRangePreset(id: 'bass', name: 'Bass (E2 - E4)', minMidi: 40, maxMidi: 64),
    VoiceRangePreset(id: 'alto', name: 'Alto (F3 - F5)', minMidi: 53, maxMidi: 77),
    VoiceRangePreset(id: 'mezzo', name: 'Mezzo-Soprano (A3 - A5)', minMidi: 57, maxMidi: 81),
    VoiceRangePreset(id: 'soprano', name: 'Soprano (C4 - C6)', minMidi: 60, maxMidi: 84),
    VoiceRangePreset(id: 'custom', name: 'Custom Range...', minMidi: 48, maxMidi: 72, isCustom: true),
  ];
}
