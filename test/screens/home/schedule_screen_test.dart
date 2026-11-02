import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dojo_partner/screens/home/schedule_screen.dart';

void main() {
  testWidgets('schedule clearly identifies the displayed walks as sample data',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScheduleScreen(),
      ),
    );

    expect(
      find.text(
        'Sample schedule — these are preview walks, not live assignments.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('sample schedule preview still renders its sample walk cards',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScheduleScreen(),
      ),
    );

    expect(find.text('Bruno'), findsNWidgets(2));
    expect(find.text('07:00 AM'), findsOneWidget);
    expect(find.text('06:00 PM'), findsOneWidget);
  });
}
