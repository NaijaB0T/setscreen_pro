import 'package:flutter_test/flutter_test.dart';
import 'package:setscreen_pro/main.dart';

void main() {
  testWidgets('SetScreenApp HomePortalScreen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SetScreenApp());

    // Verify that the setup screen title is displayed
    expect(find.text('SetScreen Pro'), findsOneWidget);

    // Verify that the "Prop Messages" card is present
    expect(find.text('Prop Messages'), findsOneWidget);
  });
}
