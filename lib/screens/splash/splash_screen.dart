import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/mobile_login_screen.dart';
import '../../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MobileLoginScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoPartnerTheme.background,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Splash PNG: इसमें ऐप का नाम पहले से मौजूद है।
            Center(
              child: Image.asset(
                'assets/icon/DOJO WALK PARTNER SPLASH.png',
                width: 280,
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.pets,
                    size: 70,
                    color: DojoPartnerTheme.primaryOrange,
                  );
                },
              ),
            ),

            // छोटा काला लोडिंग इंडिकेटर, थोड़ा नीचे।
            const Positioned(
              bottom: 55,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DojoPartnerTheme.primaryOrange,
                  ),
                ),
              ),
            ),

            // नीचे छोटा ब्रांडिंग टेक्स्ट।
            const Positioned(
              bottom: 14,
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 9,
                    color: DojoPartnerTheme.textSecondary,
                    letterSpacing: 0.2,
                  ),
                  children: [
                    TextSpan(text: 'Powered by '),
                    TextSpan(
                      text: 'DOJO WALK',
                      style: TextStyle(
                        color: DojoPartnerTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
