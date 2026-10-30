import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtitle_generator/main.dart';

void main() {
  testWidgets('App renders main navigation shell and title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SubtitleGeneratorApp(),
      ),
    );

    expect(find.text('AI Subtitle Generator'), findsOneWidget);
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
