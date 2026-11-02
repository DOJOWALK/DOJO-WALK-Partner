import 'package:flutter/material.dart';

import '../../theme.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Earnings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text(
              'Your Earnings',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: DojoPartnerTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Track your completed walks and earnings.',
              style: TextStyle(
                fontSize: 14,
                color: DojoPartnerTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            // Total balance
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: DojoPartnerTheme.primaryOrange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVAILABLE EARNINGS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '—',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Ledger connection pending',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _EarningCard(
                    title: 'Today',
                    amount: '—',
                    icon: Icons.today_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EarningCard(
                    title: 'This Week',
                    amount: '—',
                    icon: Icons.date_range_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _EarningCard(
                    title: 'This Month',
                    amount: '—',
                    icon: Icons.calendar_month_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EarningCard(
                    title: 'Walks',
                    amount: '—',
                    icon: Icons.pets_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'RECENT EARNINGS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: DojoPartnerTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: DojoPartnerTheme.primaryOrange,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Earnings preview only — these figures are not live or payable. Verified earnings will appear after the approved earnings ledger is connected.',
                      style: TextStyle(
                        fontSize: 12,
                        color: DojoPartnerTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: DojoPartnerTheme.primaryOrange,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No verified earnings are available yet. This screen will update when the approved earnings ledger is connected.',
                      style: TextStyle(
                        fontSize: 12,
                        color: DojoPartnerTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningCard extends StatelessWidget {
  const _EarningCard({
    required this.title,
    required this.amount,
    required this.icon,
  });

  final String title;
  final String amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAEAEA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: DojoPartnerTheme.primaryOrange,
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: DojoPartnerTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
