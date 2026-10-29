import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dojo_partner/app.dart';
import 'package:dojo_partner/theme.dart';
import 'package:dojo_partner/screens/home/navigation_screen.dart';

void main() {
  test('DOJO WALK brand tokens match the unified Notion UI system', () {
    expect(DojoPartnerTheme.primaryOrange, const Color(0xFFFF7900));
    expect(DojoPartnerTheme.background, const Color(0xFFFFFAF5));
    expect(DojoPartnerTheme.textPrimary, const Color(0xFF252525));
  });

  test('light theme uses Material 3 and the warm brand background', () {
    final theme = DojoPartnerTheme.light();

    expect(theme.useMaterial3, isTrue);
    expect(theme.scaffoldBackgroundColor, DojoPartnerTheme.background);
    expect(theme.colorScheme.primary, isNotNull);
  });

  testWidgets(
    'navigation does not confirm pickup when booking ID is missing',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NavigationScreen(
            time: '7:00 AM',
            dogName: 'Test Dog',
            location: 'Test pickup',
            duration: '30 minutes',
          ),
        ),
      );

      await tester.tap(find.text('Arrived at Pickup'));
      await tester.pump();

      expect(
        find.text(
          'This walk has no confirmed booking ID. Please contact support before continuing.',
        ),
        findsOneWidget,
      );
      expect(find.text('Arrived at Pickup'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('DOJO Partner app builds successfully', (tester) async {
    await tester.pumpWidget(const DojoPartnerApp());

    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
  });
}
