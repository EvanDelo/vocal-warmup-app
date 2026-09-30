abstract class AudioEngineBase {
  void playMidiNote(int midi, {double durationSeconds = 0.5, double volume = 0.9});
  void precacheMidiRange(int minMidi, int maxMidi);
  void stop();
  void dispose();
}
