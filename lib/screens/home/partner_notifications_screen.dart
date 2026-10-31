import 'package:flutter/material.dart';

import '../../theme.dart';

/// Notification inbox shell.
///
/// The Partner app does not yet have an approved notification feed contract.
/// Keep this screen honest: never render sample events as real notifications.
class PartnerNotificationsScreen extends StatelessWidget {
  const PartnerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoPartnerTheme.background,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: DojoPartnerTheme.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DojoPartnerTheme.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF0E5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 38,
                      color: DojoPartnerTheme.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Your updates will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: DojoPartnerTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Booking, walk, account and payment updates '
                    'will be shown here when notifications are connected.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: DojoPartnerTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: DojoPartnerTheme.primaryOrange,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Notifications are not connected yet. '
                            'No updates have been loaded, and this does '
                            'not mean there are no account or booking updates.',
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
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DojoPartnerTheme.border),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: DojoPartnerTheme.textSecondary,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification preferences',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: DojoPartnerTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Preferences will be available after '
                          'notification settings are connected.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: DojoPartnerTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Coming soon',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DojoPartnerTheme.textSecondary,
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
