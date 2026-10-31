import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';
import '../auth/mobile_login_screen.dart';
import '../../features/onboarding/screens/kyc_status_screen.dart';
import 'partner_support_screen.dart';
import 'partner_notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;

  String _fullName = 'Partner';
  String _walkerId = 'Not assigned';
  String _zoneName = 'Not set';
  String _service = 'Dog Walking';
  String _rating = 'Not rated';
  String _phone = '';
  String _verificationLabel = 'Verification pending';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid)
          .get();

      final data = snapshot.data();

      if (data != null) {
        final services = data['services'];
        final rating = data['rating'];

        String serviceName = 'Dog Walking';

        if (services is List && services.isNotEmpty) {
          final firstService = services.first.toString();

          if (firstService == 'dog_walking') {
            serviceName = 'Dog Walking';
          } else {
            serviceName = firstService;
          }
        }

        String ratingText = 'Not rated';

        if (rating is num) {
          ratingText = '${rating.toStringAsFixed(1)} / 5.0';
        }

        if (!mounted) return;

        setState(() {
          _fullName = _readString(
            data['fullName'],
            fallback: user.displayName ?? 'Partner',
          );

          _walkerId = _readString(
            data['walkerId'],
            fallback: 'Not assigned',
          );

          _zoneName = _readString(
            data['zoneName'],
            fallback: 'Not set',
          );

          _service = serviceName;
          _rating = ratingText;
          _verificationLabel = _verificationLabelFor(data);

          _phone = _readString(
            data['phone'],
            fallback: user.phoneNumber ?? '',
          );

          _loading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          _fullName = user.displayName ?? 'Partner';
          _phone = user.phoneNumber ?? '';
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  String _readString(
    dynamic value, {
    required String fallback,
  }) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return fallback;
  }

  String get _initial {
    final name = _fullName.trim();

    if (name.isEmpty) {
      return 'P';
    }

    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              _showComingSoon(
                context,
                'Settings',
                'Profile settings will be available here.',
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: DojoPartnerTheme.primaryOrange,
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  28,
                ),
                children: [
                  _buildProfileHeader(),

                  const SizedBox(height: 24),

                  const _SectionTitle(
                    title: 'YOUR PROFILE',
                  ),

                  const SizedBox(height: 12),

                  _ActionItem(
                    icon: Icons.person_outline,
                    title: 'Personal Details',
                    subtitle: 'Name and mobile number',
                    onTap: _openPersonalDetails,
                  ),

                  _ActionItem(
                    icon: Icons.description_outlined,
                    title: 'Documents & KYC',
                    subtitle: 'Aadhaar, PAN and verification',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const KycStatusScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  const _SectionTitle(
                    title: 'WORK INFORMATION',
                  ),

                  const SizedBox(height: 12),

                  _ProfileItem(
                    icon: Icons.location_on_outlined,
                    title: 'Primary Zone',
                    value: _zoneName,
                  ),

                  _ProfileItem(
                    icon: Icons.pets_outlined,
                    title: 'Service',
                    value: _service,
                  ),

                  _ProfileItem(
                    icon: Icons.star_outline,
                    title: 'Rating',
                    value: _rating,
                  ),

                  const SizedBox(height: 24),

                  const _SectionTitle(
                    title: 'SUPPORT & SETTINGS',
                  ),

                  const SizedBox(height: 12),

                  _ActionItem(
                    icon: Icons.notifications_none_outlined,
                    title: 'Notifications',
                    subtitle: 'View notification updates',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const PartnerNotificationsScreen(),
                        ),
                      );
                    },
                  ),

                  _ActionItem(
                    icon: Icons.support_agent_outlined,
                    title: 'DOJO Support',
                    subtitle: 'Get help with your partner account',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PartnerSupportScreen(),
                        ),
                      );
                    },
                  ),

                  _ActionItem(
                    icon: Icons.info_outline,
                    title: 'About DOJO Partner',
                    subtitle: 'App information',
                    onTap: _showAboutDialog,
                  ),

                  const SizedBox(height: 24),

                  OutlinedButton.icon(
                    onPressed: () {
                      _showLogoutDialog(context);
                    },
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(
                        double.infinity,
                        52,
                      ),
                      side: const BorderSide(
                        color: DojoPartnerTheme.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: DojoPartnerTheme.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: DojoPartnerTheme.primaryOrange,
            child: Text(
              _initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                _VerificationBadge(label: _verificationLabel),
                const SizedBox(height: 8),
                Text(
                  'Partner ID  •  $_walkerId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DojoPartnerTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPersonalDetails() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                _DetailRow(
                  icon: Icons.person_outline,
                  title: 'Full Name',
                  value: _fullName,
                ),
                const SizedBox(height: 14),
                _DetailRow(
                  icon: Icons.phone_outlined,
                  title: 'Mobile Number',
                  value: _phone.isEmpty ? 'Not available' : _phone,
                ),
                const SizedBox(height: 14),
                _DetailRow(
                  icon: Icons.badge_outlined,
                  title: 'Partner ID',
                  value: _walkerId,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showComingSoon(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'DOJO Partner',
      applicationVersion: '1.0.0',
      applicationLegalese: '© DOJO',
      children: const [
        SizedBox(height: 12),
        Text(
          'DOJO Partner helps verified walkers manage their work, '
          'walks, schedules and earnings.',
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout from DOJO Partner?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _performLogout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MobileLoginScreen(),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Logout failed. Please try again.',
          ),
        ),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: DojoPartnerTheme.textSecondary,
      ),
    );
  }
}

String _verificationLabelFor(Map<String, dynamic> data) {
  final status = (data['status'] ?? '').toString().trim().toLowerCase();
  final isApproved = data['isApproved'] == true;
  final isActive = data['isActive'] == true;

  if (isApproved && isActive && status == 'approved') {
    return 'Verified Partner';
  }
  if (status == 'suspended' || status == 'disabled' ||
      (isApproved && !isActive)) {
    return 'Account inactive';
  }
  if (status == 'rejected') {
    return 'Application not approved';
  }
  if (status == 'under_review' || data['applicationSubmitted'] == true) {
    return 'Verification in review';
  }
  return 'Verification pending';
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final verified = label == 'Verified Partner';
    final rejected = label == 'Application not approved';
    final foreground = verified
        ? const Color(0xFF237A3B)
        : rejected
            ? const Color(0xFFB3261E)
            : const Color(0xFF9A5700);
    final background = verified
        ? const Color(0xFFEAF8EE)
        : rejected
            ? const Color(0xFFFCE8E6)
            : const Color(0xFFFFF3E0);
    final icon = verified
        ? Icons.verified
        : rejected
            ? Icons.error_outline
            : Icons.hourglass_top_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: DojoPartnerTheme.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: DojoPartnerTheme.primaryOrange,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: DojoPartnerTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DojoPartnerTheme.border,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 3,
        ),
        leading: Icon(
          icon,
          color: DojoPartnerTheme.primaryOrange,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: DojoPartnerTheme.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: DojoPartnerTheme.textSecondary,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: DojoPartnerTheme.primaryOrange,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: DojoPartnerTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
