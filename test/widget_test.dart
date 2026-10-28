import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dojo_partner/app.dart';
import 'package:dojo_partner/theme.dart';

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

  testWidgets('DOJO Partner app builds successfully', (tester) async {
    await tester.pumpWidget(const DojoPartnerApp());

    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
  });
}
