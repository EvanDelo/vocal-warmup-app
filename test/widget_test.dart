import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_warmup/main.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const VocalWarmupApp());
    expect(find.text('Vocal Warmup'), findsOneWidget);
    expect(find.text('Offline • Synthesized'), findsOneWidget);
  });
}
