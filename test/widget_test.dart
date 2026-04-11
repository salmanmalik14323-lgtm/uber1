import 'package:flutter_test/flutter_test.dart';

import 'package:uber_ride/main.dart';

void main() {
  testWidgets('Login screen shows', (WidgetTester tester) async {
    await tester.pumpWidget(const UberRideApp());
    await tester.pump();
    expect(find.text('Uber Ride'), findsOneWidget);
    expect(find.text('Skip — Continue as guest'), findsOneWidget);
  });
}
