import 'package:flutter/material.dart';

import '../../theme.dart';
import 'partner_home_screen.dart';

class WalkCompletedScreen extends StatelessWidget {
  const WalkCompletedScreen({
    super.key,
    required this.dogName,
    required this.walkType,
    required this.scheduledTime,
    required this.durationSeconds,
    required this.distanceKm,
    required this.location,
    this.earnings = 0,
    this.peeCount = 0,
    this.poopCount = 0,
  });

  final String dogName;
  final String walkType;
  final String scheduledTime;
  final int durationSeconds;
  final double distanceKm;
  final String location;
  final double earnings;
  final int peeCount;
  final int poopCount;

  String get _durationText {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;

    if (minutes == 0) {
      return '${seconds}s';
    }

    return '${minutes}m ${seconds}s';
  }

  String get _distanceText =>
      '${distanceKm.toStringAsFixed(2)} km';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoPartnerTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    Center(
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF2E7D32),
                          size: 54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Walk Completed!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          color: DojoPartnerTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "$dogName's walk has been completed successfully.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: DojoPartnerTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Walk Summary',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: DojoPartnerTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: DojoPartnerTheme.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1E8),
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.pets,
                                  color:
                                      DojoPartnerTheme.primaryOrange,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dogName,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      walkType,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: DojoPartnerTheme
                                            .textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          _SummaryRow(
                            icon: Icons.timer_outlined,
                            label: 'Walk Duration',
                            value: _durationText,
                          ),
                          const SizedBox(height: 18),
                          _SummaryRow(
                            icon: Icons.route_outlined,
                            label: 'Distance',
                            value: _distanceText,
                          ),
                          const SizedBox(height: 18),
                          _SummaryRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Scheduled Time',
                            value: scheduledTime.isEmpty
                                ? 'Not specified'
                                : scheduledTime,
                          ),
                          const SizedBox(height: 18),
                          _SummaryRow(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: location.isEmpty
                                ? 'Not specified'
                                : location,
                          ),
                          const SizedBox(height: 18),
                          _SummaryRow(
                            icon: Icons.water_drop_outlined,
                            label: 'Pee',
                            value: '$peeCount times',
                          ),
                          const SizedBox(height: 18),
                          _SummaryRow(
                            icon: Icons.pets_outlined,
                            label: 'Poop',
                            value: '$poopCount times',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: DojoPartnerTheme.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                color:
                                    DojoPartnerTheme.primaryOrange,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Walk Earnings',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Pending verification',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: DojoPartnerTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Earnings will appear in your Earnings screen after this walk is verified and recorded. This completion screen does not calculate or confirm payout.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: DojoPartnerTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const PartnerHomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Done'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: DojoPartnerTheme.primaryOrange,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: DojoPartnerTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: DojoPartnerTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
