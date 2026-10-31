import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dojo_partner/screens/home/partner_notifications_screen.dart';

void main() {
  testWidgets('notification inbox clearly shows the unconnected state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PartnerNotificationsScreen()),
    );

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Your updates will appear here'), findsOneWidget);
    expect(
      find.textContaining('notifications are connected'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Notifications are not connected yet'),
      findsOneWidget,
    );
    expect(find.text('Coming soon'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification inbox does not display fabricated notification items', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PartnerNotificationsScreen()),
    );

    expect(find.byType(ListTile), findsNothing);
    expect(find.text('Booking confirmed'), findsNothing);
    expect(find.text('New walk assigned'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
