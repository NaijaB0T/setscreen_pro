import 'package:flutter_test/flutter_test.dart';
import 'package:setscreen_pro/main.dart';

void main() {
  testWidgets('SetScreenApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SetScreenApp());

    // Verify that the contact name is displayed
    expect(find.text('Michael Naizu'), findsOneWidget);

    // Verify that the text input displays the placeholder "iMessage"
    expect(find.text('iMessage'), findsOneWidget);
  });
}
