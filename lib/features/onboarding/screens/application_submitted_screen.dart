import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../theme.dart';

const Color _orange = DojoPartnerTheme.primaryOrange;
const Color _background = DojoPartnerTheme.background;
const Color _text = DojoPartnerTheme.textPrimary;
const Color _muted = DojoPartnerTheme.textSecondary;
const Color _green = Color(0xFF23834B);

class ApplicationSubmittedScreen extends StatefulWidget {
  const ApplicationSubmittedScreen({super.key});

  @override
  State<ApplicationSubmittedScreen> createState() =>
      _ApplicationSubmittedScreenState();
}

class _ApplicationSubmittedScreenState
    extends State<ApplicationSubmittedScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Are you sure you want to log out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _muted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } catch (e) {
      debugPrint('Logout error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to log out. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _openHelpSupport() async {
    final categoryController =
        ValueNotifier<String>('Application Status');

    final messageController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool sending = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Help & Support',
                style: TextStyle(
                  color: _text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What do you need help with?',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<String>(
                    valueListenable: categoryController,
                    builder: (context, category, _) {
                      return DropdownButtonFormField<String>(
                        initialValue: category,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Application Status',
                            child: Text('Application Status'),
                          ),
                          DropdownMenuItem(
                            value: 'KYC Documents',
                            child: Text('KYC Documents'),
                          ),
                          DropdownMenuItem(
                            value: 'Personal Details',
                            child: Text('Personal Details'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: sending
                            ? null
                            : (value) {
                                if (value != null) {
                                  categoryController.value = value;
                                }
                              },
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: messageController,
                    enabled: !sending,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: 'Describe your issue...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: sending
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: _muted),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: sending
                      ? null
                      : () async {
                          final message =
                              messageController.text.trim();

                          if (message.isEmpty) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please describe your issue.',
                                  ),
                                ),
                              );
                            return;
                          }

                          final user =
                              FirebaseAuth.instance.currentUser;

                          if (user == null) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please log in again to contact support.',
                                  ),
                                ),
                              );
                            return;
                          }

                          setDialogState(() => sending = true);

                          try {
                            await FirebaseFirestore.instance
                                .collection('support_requests')
                                .add({
                              'userId': user.uid,
                              'walkerId': user.uid,
                              'category': categoryController.value,
                              'message': message,
                              'status': 'open',
                              'createdAt':
                                  FieldValue.serverTimestamp(),
                              'updatedAt':
                                  FieldValue.serverTimestamp(),
                            });

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            if (!mounted) return;

                            ScaffoldMessenger.of(this.context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Support request submitted successfully.',
                                  ),
                                ),
                              );
                          } catch (e) {
                            debugPrint(
                              'Support request error: $e',
                            );

                            if (!dialogContext.mounted) return;

                            setDialogState(
                              () => sending = false,
                            );

                            ScaffoldMessenger.of(this.context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Unable to submit your request. Please try again.',
                                  ),
                                ),
                              );
                          }
                        },
                  child: sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Request'),
                ),
              ],
            );
          },
        );
      },
    );

    categoryController.dispose();
    messageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _user?.uid;

    if (uid == null) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(
          child: Text(
            'Session expired. Please log in again.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(
              Icons.pets_rounded,
              color: _orange,
              size: 27,
            ),
            SizedBox(width: 8),
            Text(
              'DOJO WALK',
              style: TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More options',
            icon: const Icon(
              Icons.more_vert_rounded,
              color: _text,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'support') {
                _openHelpSupport();
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'support',
                child: Row(
                  children: [
                    Icon(
                      Icons.support_agent_rounded,
                      color: _orange,
                    ),
                    SizedBox(width: 12),
                    Text('Help & Support'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: _text,
                    ),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('walkers')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to load your application status. '
                  'Please try again later.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: _orange,
              ),
            );
          }

          final data = snapshot.data?.data() ?? {};

          final rawStatus = (data['status'] ?? 'under_review')
              .toString()
              .toLowerCase();

          final isApproved = data['isApproved'] == true;
          final isActive = data['isActive'] == true;

          final statusLabel = isApproved && isActive
              ? 'APPROVED'
              : rawStatus == 'rejected'
                  ? 'REJECTED'
                  : 'UNDER REVIEW';

          final statusMessage = isApproved && isActive
              ? 'Your account is approved and activated. You can '
                  'continue to the Partner Home when your app allows it.'
              : rawStatus == 'rejected'
                  ? 'Your application needs attention. Please contact '
                      'support for the next steps.'
                  : 'Our team is reviewing your details and documents. '
                      'We will update your application status when '
                      'verification is complete.';

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                28,
              ),
              children: [
                const SizedBox(height: 12),

                // Application submitted icon.
                Center(
                  child: Container(
                    height: 88,
                    width: 88,
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: _green,
                      size: 62,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'Application Submitted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _text,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Your application has been successfully submitted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 28),

                _progressCard(),

                const SizedBox(height: 20),

                _statusCard(
                  statusLabel: statusLabel,
                  statusMessage: statusMessage,
                  rejected: rawStatus == 'rejected',
                  approved: isApproved && isActive,
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFE1C7),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        color: _orange,
                        size: 23,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You cannot accept walks until your application '
                          'is approved and your account is activated.',
                          style: TextStyle(
                            color: _text,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'You can check this screen again later to see '
                  'your latest application status.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _progressCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
          const Text(
            'APPLICATION PROGRESS',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 22),
          _progressStep(
            icon: Icons.check_circle_rounded,
            title: 'Application Received',
            subtitle: 'Your application has been submitted.',
            completed: true,
            last: false,
          ),
          _progressStep(
            icon: Icons.hourglass_top_rounded,
            title: 'Verification In Progress',
            subtitle: 'Your details and documents are being reviewed.',
            completed: false,
            last: false,
          ),
          _progressStep(
            icon: Icons.verified_user_outlined,
            title: 'Account Approval',
            subtitle: 'Pending completion of verification.',
            completed: false,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _progressStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool completed,
    required bool last,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 23,
                  color: completed ? _green : _orange,
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: const BoxConstraints(
                        minHeight: 28,
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                      ),
                      color: const Color(0xFFEAEAEA),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard({
    required String statusLabel,
    required String statusMessage,
    required bool rejected,
    required bool approved,
  }) {
    final statusColor =
        rejected ? Colors.red : approved ? _green : _orange;

    return Container(
      padding: const EdgeInsets.all(18),
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
          const Text(
            'CURRENT STATUS',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  rejected
                      ? Icons.error_outline_rounded
                      : approved
                          ? Icons.verified_rounded
                          : Icons.schedule_rounded,
                  color: statusColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            statusMessage,
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
