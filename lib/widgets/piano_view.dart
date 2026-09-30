import 'package:flutter/material.dart';
import '../models/music_theory.dart';

class PianoView extends StatefulWidget {
  final int? activeMidi;
  final int rootMidi;
  final Function(int midi) onKeyTapped;

  const PianoView({
    super.key,
    required this.activeMidi,
    required this.rootMidi,
    required this.onKeyTapped,
  });

  @override
  State<PianoView> createState() => _PianoViewState();
}

class _PianoViewState extends State<PianoView> {
  final ScrollController _scrollController = ScrollController();

  static const double whiteKeyWidth = 46.0;
  static const double whiteKeyHeight = 160.0;
  static const double blackKeyWidth = 28.0;
  static const double blackKeyHeight = 100.0;

  // Range from C2 (36) to C6 (84) - 4 complete octaves
  static const int minMidi = 36;
  static const int maxMidi = 84;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToMidi(widget.rootMidi, animate: false);
    });
  }

  @override
  void didUpdateWidget(covariant PianoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeMidi != null && widget.activeMidi != oldWidget.activeMidi) {
      _scrollToMidi(widget.activeMidi!, animate: true);
    } else if (widget.rootMidi != oldWidget.rootMidi) {
      _scrollToMidi(widget.rootMidi, animate: true);
    }
  }

  void _scrollToMidi(int midi, {bool animate = true}) {
    if (!_scrollController.hasClients) return;

    // Find the horizontal offset of this MIDI note
    int whiteKeyIndex = 0;
    for (int m = minMidi; m < midi; m++) {
      if (!_isBlackKey(m)) whiteKeyIndex++;
    }

    final targetX = (whiteKeyIndex * whiteKeyWidth) - 120.0;
    final clampedX = targetX.clamp(0.0, _scrollController.position.maxScrollExtent);

    if (animate) {
      _scrollController.animateTo(
        clampedX,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuad,
      );
    } else {
      _scrollController.jumpTo(clampedX);
    }
  }

  static bool _isBlackKey(int midi) {
    final note = midi % 12;
    return note == 1 || note == 3 || note == 6 || note == 8 || note == 10;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate list of white keys
    final List<int> whiteKeys = [];
    for (int m = minMidi; m <= maxMidi; m++) {
      if (!_isBlackKey(m)) whiteKeys.add(m);
    }

    final totalWidth = whiteKeys.length * whiteKeyWidth;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Piano fallboard casing
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4, right: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Red Felt Strip across the top of the keybed
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFB71C1C), // Authentic crimson felt
              borderRadius: BorderRadius.circular(2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),

          // Scrollable Piano Keys Bed
          SizedBox(
            height: whiteKeyHeight,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: totalWidth,
                height: whiteKeyHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // --- WHITE KEYS ---
                    Row(
                      children: whiteKeys.map((midi) {
                        final isActive = widget.activeMidi == midi;
                        final isRoot = widget.rootMidi == midi;
                        final noteInfo = NoteInfo.fromMidi(midi);
                        final isMiddleC = midi == 60;

                        return GestureDetector(
                          onTapDown: (_) => widget.onKeyTapped(midi),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: whiteKeyWidth,
                            height: whiteKeyHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isActive
                                    ? [
                                        const Color(0xFFFFE082),
                                        const Color(0xFFFFB300),
                                      ]
                                    : (isRoot
                                        ? [
                                            const Color(0xFFE3F2FD),
                                            const Color(0xFFBBDEFB),
                                          ]
                                        : [
                                            Colors.white,
                                            const Color(0xFFF7F5F0),
                                            const Color(0xFFECE8E0),
                                          ]),
                              ),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(5)),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFFFFA000)
                                    : (isRoot ? Colors.blue.shade400 : const Color(0xFFCCCCCC)),
                                width: isActive || isRoot ? 1.5 : 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 3,
                                  offset: const Offset(0, 3),
                                ),
                                if (isActive)
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                // Subtle bottom lip shadow of ivory key
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: 4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                                    ),
                                  ),
                                ),
                                // Key Label
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isMiddleC)
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 2),
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade700,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'MID',
                                            style: TextStyle(
                                              fontSize: 7,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        noteInfo.name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: (isRoot || isActive || isMiddleC) ? FontWeight.bold : FontWeight.w600,
                                          color: isActive
                                              ? const Color(0xFF3E2723)
                                              : (isRoot ? Colors.blue.shade900 : const Color(0xFF333333)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // --- BLACK KEYS OVERLAY ---
                    ...whiteKeys.asMap().entries.map((entry) {
                      final index = entry.key;
                      final whiteMidi = entry.value;
                      final blackMidi = whiteMidi + 1;

                      if (!_isBlackKey(blackMidi) || blackMidi > maxMidi) {
                        return const SizedBox.shrink();
                      }

                      final isActive = widget.activeMidi == blackMidi;
                      final isRoot = widget.rootMidi == blackMidi;
                      final noteInfo = NoteInfo.fromMidi(blackMidi);
                      // Center black key over the boundary of this white key and the next
                      final leftOffset = ((index + 1) * whiteKeyWidth) - (blackKeyWidth / 2);

                      return Positioned(
                        left: leftOffset,
                        top: 0,
                        child: GestureDetector(
                          onTapDown: (_) => widget.onKeyTapped(blackMidi),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: blackKeyWidth,
                            height: blackKeyHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isActive
                                    ? [
                                        const Color(0xFFFFB300),
                                        const Color(0xFFFF8F00),
                                      ]
                                    : (isRoot
                                        ? [
                                            const Color(0xFF1976D2),
                                            const Color(0xFF0D47A1),
                                          ]
                                        : [
                                            const Color(0xFF3A3A3A),
                                            const Color(0xFF1F1F1F),
                                            const Color(0xFF111111),
                                          ]),
                              ),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFFFFD54F)
                                    : (isRoot ? Colors.lightBlueAccent : const Color(0xFF000000)),
                                width: isActive || isRoot ? 1.5 : 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  offset: const Offset(2, 4),
                                ),
                                if (isActive)
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                            alignment: Alignment.bottomCenter,
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              noteInfo.name,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? Colors.black
                                    : (isRoot ? Colors.white : Colors.white70),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
