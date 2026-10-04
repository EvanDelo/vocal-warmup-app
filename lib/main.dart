import 'package:flutter/material.dart';
import 'models/music_theory.dart';
import 'services/warmup_sequencer.dart';
import 'widgets/piano_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VocalWarmupApp());
}

class VocalWarmupApp extends StatelessWidget {
  const VocalWarmupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocal Warmup',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5C6BC0),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const WarmupHomeScreen(),
    );
  }
}

class WarmupHomeScreen extends StatefulWidget {
  const WarmupHomeScreen({super.key});

  @override
  State<WarmupHomeScreen> createState() => _WarmupHomeScreenState();
}

class _WarmupHomeScreenState extends State<WarmupHomeScreen> {
  late final WarmupSequencer _sequencer;

  @override
  void initState() {
    super.initState();
    _sequencer = WarmupSequencer();
    _sequencer.addListener(_onSequencerUpdate);
  }

  void _onSequencerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sequencer.removeListener(_onSequencerUpdate);
    _sequencer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentRoot = _sequencer.currentRootInfo;
    final activeNote = _sequencer.activeNoteInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.graphic_eq_rounded, color: Colors.indigoAccent),
            SizedBox(width: 10),
            Text('Vocal Warmup', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade600, width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 16, color: Colors.green),
                SizedBox(width: 6),
                Text(
                  'Offline • Synthesized',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pitch Reference Display Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT ROOT KEY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${currentRoot.name} (Root) • ${_sequencer.currentPeakInfo.name} (Peak)',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _sequencer.isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _sequencer.isAscending ? 'Ascending' : 'Descending',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Large Sounding Pitch Display
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: activeNote != null
                                ? Colors.amber.shade600
                                : theme.dividerColor.withValues(alpha: 0.2),
                            width: activeNote != null ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              activeNote != null ? activeNote.name : 'PAUSED',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: activeNote != null
                                    ? Colors.amber.shade800
                                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                              ),
                            ),
                            Text(
                              activeNote != null
                                  ? '${activeNote.frequency.toStringAsFixed(1)} Hz'
                                  : 'Press Play to Begin Pattern',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Piano Roll View
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pitch Keyboard View',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Text(
                            'Tap any key to audition',
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      PianoView(
                        activeMidi: _sequencer.activeNoteMidi,
                        rootMidi: _sequencer.currentRootMidi,
                        onKeyTapped: (midi) {
                          _sequencer.setKeyAndAudition(midi);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sequencer Controls (Play / Pause / Next / Prev)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    iconSize: 28,
                    onPressed: () => _sequencer.stepKey(-1),
                    icon: const Icon(Icons.arrow_downward),
                    tooltip: 'Step Down Semitone (-1)',
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: _sequencer.isPlaying ? Colors.red.shade600 : theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: _sequencer.togglePlay,
                    icon: Icon(_sequencer.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
                    label: Text(
                      _sequencer.isPlaying ? 'PAUSE' : 'START WARMUP',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton.filledTonal(
                    iconSize: 28,
                    onPressed: () => _sequencer.stepKey(1),
                    icon: const Icon(Icons.arrow_upward),
                    tooltip: 'Step Up Semitone (+1)',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Configuration Section
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exercise Pattern Picker
                      const Text(
                        'Warmup Exercise Pattern',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        key: ValueKey('pattern_${_sequencer.currentPattern.id}'),
                        initialValue: _sequencer.currentPattern.id,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ExercisePattern.presets.map((pattern) {
                          return DropdownMenuItem<String>(
                            value: pattern.id,
                            child: Text(pattern.name),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) {
                            final p = ExercisePattern.presets.firstWhere(
                              (item) => item.id == id,
                              orElse: () => ExercisePattern.presets[0],
                            );
                            _sequencer.setPattern(p);
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Voice Type Preset
                      const Text(
                        'Voice Type & Range',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        key: ValueKey('range_${_sequencer.currentRange.id}'),
                        initialValue: _sequencer.currentRange.id,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: VoiceRangePreset.presets.map((preset) {
                          return DropdownMenuItem<String>(
                            value: preset.id,
                            child: Text(preset.name),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) {
                            final r = VoiceRangePreset.presets.firstWhere(
                              (item) => item.id == id,
                              orElse: () => VoiceRangePreset.presets[0],
                            );
                            _sequencer.setVoiceRange(r);
                          }
                        },
                      ),

                      if (_sequencer.currentRange.isCustom) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Custom Vocal Limits:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    '${NoteInfo.fromMidi(_sequencer.minMidi).name} (Min)  to  ${NoteInfo.fromMidi(_sequencer.maxMidi).name} (Max Sung)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'The exercise stops ascending when the pattern\'s highest pitch hits ${NoteInfo.fromMidi(_sequencer.maxMidi).name} (Top root: ${NoteInfo.fromMidi(_sequencer.effectiveMaxRoot).name})',
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 4),
                              RangeSlider(
                                values: RangeValues(
                                  _sequencer.minMidi.toDouble(),
                                  _sequencer.maxMidi.toDouble(),
                                ),
                                min: 36, // C2
                                max: 84, // C6
                                divisions: 48,
                                labels: RangeLabels(
                                  NoteInfo.fromMidi(_sequencer.minMidi).name,
                                  NoteInfo.fromMidi(_sequencer.maxMidi).name,
                                ),
                                onChanged: (values) {
                                  _sequencer.setCustomRange(
                                    minMidi: values.start.round(),
                                    maxMidi: values.end.round(),
                                    precache: false,
                                  );
                                },
                                onChangeEnd: (values) {
                                  _sequencer.finishCustomRange();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Articulation Selector (Legato vs Staccato)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Articulation',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _sequencer.articulation == Articulation.staccato
                                ? 'Crisp & Detached'
                                : 'Smooth & Connected',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<Articulation>(
                          segments: const [
                            ButtonSegment<Articulation>(
                              value: Articulation.legato,
                              label: Text('Legato'),
                              icon: Icon(Icons.waves_rounded),
                            ),
                            ButtonSegment<Articulation>(
                              value: Articulation.staccato,
                              label: Text('Staccato'),
                              icon: Icon(Icons.grain_rounded),
                            ),
                          ],
                          selected: {_sequencer.articulation},
                          onSelectionChanged: (newSelection) {
                            _sequencer.setArticulation(newSelection.first);
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tempo Slider (BPM) up to 240 BPM
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tempo',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                iconSize: 18,
                                icon: const Icon(Icons.remove),
                                onPressed: () => _sequencer.setBpm(_sequencer.bpm - 5),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_sequencer.bpm} BPM',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                iconSize: 18,
                                icon: const Icon(Icons.add),
                                onPressed: () => _sequencer.setBpm(_sequencer.bpm + 5),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Slider(
                        value: _sequencer.bpm.toDouble().clamp(50.0, 240.0),
                        min: 50,
                        max: 240,
                        divisions: 38,
                        label: '${_sequencer.bpm} BPM',
                        onChanged: (val) => _sequencer.setBpm(val.round()),
                      ),

                      // Auto-Reverse Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Auto-Reverse at Range Limit', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('Descend back down after reaching the highest key', style: TextStyle(fontSize: 12)),
                        value: _sequencer.autoReverse,
                        onChanged: (val) => _sequencer.setAutoReverse(val),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
