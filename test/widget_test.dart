import 'package:flutter_test/flutter_test.dart';

import 'package:open_note/widgets/splash_screen.dart';

void main() {
  testWidgets('Splash app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SplashApp());
    expect(find.text('OpenNote'), findsOneWidget);
  });
}
