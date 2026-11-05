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

  testWidgets('sample walk cards remain available in the preview',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScheduleScreen(),
      ),
    );

    expect(find.text('07:00 AM'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('06:00 PM'),
      250,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('06:00 PM'), findsOneWidget);
  });
}
