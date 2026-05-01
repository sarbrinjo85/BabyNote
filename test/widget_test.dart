import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:babynote/app.dart';

void main() {
  testWidgets('App boots and shows the welcome message', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BabyNoteApp()));
    await tester.pumpAndSettle();

    // Test environment defaults to en_US — assert against the English string.
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('BabyNote'), findsOneWidget); // AppBar title
  });
}
