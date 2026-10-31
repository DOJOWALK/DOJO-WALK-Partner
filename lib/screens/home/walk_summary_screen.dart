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
    this.gpsTrackingRecorded = false,
  });

  final String dogName;
  final String walkType;
  final String scheduledTime;
  final int durationSeconds;
  final double distanceKm;
  final String location;
  final int peeCount;
  final int poopCount;

  /// True only when this device received and accepted an initial GPS fix.
  /// This is not server-side verification of the route or walk.
  final bool gpsTrackingRecorded;

  String get _durationLabel {
    if (!gpsTrackingRecorded || durationSeconds <= 0) {
      return 'Not recorded';
    }

    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  String get _distanceLabel {
    if (!gpsTrackingRecorded ||
        !distanceKm.isFinite ||
        distanceKm < 0) {
      return 'Not available';
    }
    return '${distanceKm.toStringAsFixed(2)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoPartnerTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 52),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF2E7D32),
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Walk Record Saved',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: DojoPartnerTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$dogName’s walk details were saved successfully.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: DojoPartnerTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFD7B8)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: DojoPartnerTheme.primaryOrange,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'This is a Partner-recorded summary. '
                                'DOJO WALK verification and payout eligibility '
                                'are not confirmed on this screen.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: DojoPartnerTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SummaryCard(
                        title: 'Walk Details',
                        children: [
                          _SummaryRow(
                            icon: Icons.pets,
                            label: 'Dog',
                            value: dogName,
                          ),
                          _SummaryRow(
                            icon: Icons.directions_walk,
                            label: 'Walk type',
                            value: walkType,
                          ),
                          _SummaryRow(
                            icon: Icons.schedule,
                            label: 'Scheduled time',
                            value: scheduledTime,
                          ),
                          _SummaryRow(
                            icon: Icons.location_on_outlined,
                            label: 'Service location',
                            value: location,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SummaryCard(
                        title: 'Recorded Activity',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _MetricTile(
                                  icon: Icons.timer_outlined,
                                  label: 'Duration',
                                  value: _durationLabel,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MetricTile(
                                  icon: Icons.route_outlined,
                                  label: 'Distance',
                                  value: _distanceLabel,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _NoteTile(
                                  emoji: '💧',
                                  label: 'Pee',
                                  count: peeCount,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _NoteTile(
                                  emoji: '💩',
                                  label: 'Poop',
                                  count: poopCount,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            gpsTrackingRecorded
                                ? 'GPS data was recorded on this device; server-side route verification is pending.'
                                : 'A valid GPS start was not recorded. Duration and distance are therefore not shown as verified measurements.',
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: DojoPartnerTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Pee and poop counts are notes entered by the Partner.',
                            style: TextStyle(
                              fontSize: 11,
                              color: DojoPartnerTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 54,
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
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DojoPartnerTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: DojoPartnerTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: DojoPartnerTheme.primaryOrange),
          const SizedBox(width: 10),
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: DojoPartnerTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? 'Not available' : value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: DojoPartnerTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: DojoPartnerTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 19, color: DojoPartnerTheme.primaryOrange),
          const SizedBox(height: 7),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: DojoPartnerTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: DojoPartnerTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({
    required this.emoji,
    required this.label,
    required this.count,
  });

  final String emoji;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: DojoPartnerTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: DojoPartnerTheme.textSecondary,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: DojoPartnerTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
