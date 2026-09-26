import 'package:flutter_test/flutter_test.dart';
import 'package:wearsy_mobile/main.dart';

void main() {
  testWidgets('WearsyApp smoke test renders login screen', (WidgetTester tester) async {
    // Build WearsyApp and trigger a frame.
    await tester.pumpWidget(const WearsyApp());
    await tester.pump();

    // Verify WEARSY title or brand text exists on login screen
    expect(find.text('WEARSY'), findsWidgets);
  });
}
