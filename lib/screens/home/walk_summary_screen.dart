import 'package:flutter/material.dart';

import '../../theme.dart';
import 'partner_home_screen.dart';

class WalkSummaryScreen extends StatelessWidget {
  const WalkSummaryScreen({
    super.key,
    required this.dogName,
    required this.walkType,
    required this.scheduledTime,
    required this.durationSeconds,
    required this.distanceKm,
    required this.location,
    this.peeCount = 0,
    this.poopCount = 0,
  });

  final String dogName;
  final String walkType;
  final String scheduledTime;
  final int durationSeconds;
  final double distanceKm;
  final String location;
  final int peeCount;
  final int poopCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoPartnerTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              Container(
                width: 82,
                height: 82,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF2E7D32),
                  size: 48,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Walk Completed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: DojoPartnerTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                '$dogName’s walk has been completed successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: DojoPartnerTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: DojoPartnerTheme.border,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.pets,
                          size: 20,
                          color: DojoPartnerTheme.primaryOrange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dogName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      walkType,
                      style: const TextStyle(
                        fontSize: 14,
                        color: DojoPartnerTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 14,
                        color: DojoPartnerTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PartnerHomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
