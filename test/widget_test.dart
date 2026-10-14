import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dojo_partner/app.dart';
import 'package:dojo_partner/screens/splash/splash_screen.dart';

void main() {
  testWidgets('DOJO Partner app loads splash screen', (tester) async {
    await tester.pumpWidget(const DojoPartnerApp());

    // ऐप का MaterialApp सही तरीके से खुलना चाहिए।
    expect(find.byType(MaterialApp), findsOneWidget);

    // शुरुआती स्क्रीन SplashScreen होनी चाहिए।
    expect(find.byType(SplashScreen), findsOneWidget);

    // Splash screen का branding text दिखाई देना चाहिए।
    expect(find.text('Powered by '), findsOneWidget);
    expect(find.text('DOJO WALK'), findsOneWidget);

    // Loading indicator मौजूद होना चाहिए।
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Timer को dispose करने के लिए ऐप को दूसरी स्क्रीन पर
    // जाने से पहले test समाप्त होने दें।
    await tester.pump(const Duration(seconds: 1));
  });
}
