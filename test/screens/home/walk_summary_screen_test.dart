import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dojo_partner/screens/home/walk_summary_screen.dart';

void main() {
  Widget buildSummary({
    bool gpsTrackingRecorded = false,
    int durationSeconds = 1800,
    double distanceKm = 1.25,
  }) {
    return MaterialApp(
      home: WalkSummaryScreen(
        dogName: 'Bruno',
        walkType: 'Regular Walk',
        scheduledTime: '7:00 AM',
        durationSeconds: durationSeconds,
        distanceKm: distanceKm,
        location: 'Crossings Republik',
        peeCount: 2,
        poopCount: 1,
        gpsTrackingRecorded: gpsTrackingRecorded,
      ),
    );
  }

  testWidgets('shows walk details and partner-entered activity notes',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1000));
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSummary(gpsTrackingRecorded: true));
    await tester.pumpAndSettle();

    expect(find.text('Walk Record Saved'), findsOneWidget);
    expect(find.text('Bruno'), findsOneWidget);
    expect(find.text('Regular Walk'), findsOneWidget);
    expect(find.text('7:00 AM'), findsOneWidget);
    expect(find.text('Crossings Republik'), findsOneWidget);
    expect(find.text('30m 0s'), findsOneWidget);
    expect(find.text('1.25 km'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(
      find.textContaining('server-side route verification is pending'),
      findsOneWidget,
    );
    expect(
      find.textContaining('payout eligibility are not confirmed'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not present duration or distance as verified without GPS',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1000));
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSummary(gpsTrackingRecorded: false));
    await tester.pumpAndSettle();

    expect(find.text('Not recorded'), findsOneWidget);
    expect(find.text('Not available'), findsOneWidget);
    expect(find.text('30m 0s'), findsNothing);
    expect(find.text('1.25 km'), findsNothing);
    expect(
      find.textContaining('A valid GPS start was not recorded'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles invalid distance values without formatting crashes',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1000));
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildSummary(
        gpsTrackingRecorded: true,
        durationSeconds: 0,
        distanceKm: double.nan,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not recorded'), findsOneWidget);
    expect(find.text('Not available'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
