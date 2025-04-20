
import 'package:flutter_test/flutter_test.dart';
import 'package:greyappnew/main.dart';

void main() {
  testWidgets('GreyApp loads and displays UI elements', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(GreyApp());

    // Verify that the app title is displayed
    expect(find.text("Grey Water Monitor"), findsOneWidget);

    // Verify that the "Refresh Data" button exists
    expect(find.text("Refresh Data"), findsOneWidget);

    // Verify that at least one sensor card is displayed
    expect(find.text("pH Level"), findsOneWidget);
    expect(find.text("Turbidity"), findsOneWidget);
    expect(find.text("Water Level"), findsOneWidget);
  });
}
