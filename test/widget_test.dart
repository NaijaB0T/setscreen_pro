import 'package:flutter_test/flutter_test.dart';
import 'package:setscreen_pro/main.dart';

void main() {
  testWidgets('SetScreenApp SetupScreen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SetScreenApp());

    // Verify that the setup screen title is displayed
    expect(find.text('SetScreen Dashboard'), findsOneWidget);

    // Verify that the "START TAKE" button is present
    expect(find.text('START TAKE'), findsOneWidget);
  });
}
