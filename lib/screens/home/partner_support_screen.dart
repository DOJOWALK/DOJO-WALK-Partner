import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../theme.dart';

class PartnerSupportScreen extends StatefulWidget {
  const PartnerSupportScreen({super.key});

  @override
  State<PartnerSupportScreen> createState() => _PartnerSupportScreenState();
}

class _PartnerSupportScreenState extends State<PartnerSupportScreen> {
  static const _categories = [
    'Application Status',
    'KYC Documents',
    'Booking & Walk',
    'Payment & Earnings',
    'Profile & Account',
    'App Technical Issue',
    'Other',
  ];

  final _messageController = TextEditingController();
  String _category = _categories.first;
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_sending) return;
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      _showMessage('Please describe your issue.');
      return;
    }
    if (message.length < 10) {
      _showMessage('Please add a little more detail (at least 10 characters).');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Your session has expired. Please log in again.');
      return;
    }

    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('support_requests').add({
        'userId': user.uid,
        'walkerId': user.uid,
        'category': _category,
        'message': message,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _messageController.clear();
      setState(() => _category = _categories.first);
      _showMessage('Support request submitted.');
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showMessage(
        e.code == 'permission-denied'
            ? 'Support access is currently unavailable. Please contact DOJO Support through the existing channel.'
            : 'Could not submit your request. Please check your connection and retry.',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not submit your request. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _dateLabel(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate().toLocal();
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }
    return 'Date pending';
  }

  String _statusLabel(dynamic raw) {
    final status = (raw ?? 'open').toString().toLowerCase();
    switch (status) {
      case 'open':
      case 'pending':
        return 'Open';
      case 'in_progress':
      case 'assigned':
        return 'In progress';
      case 'resolved':
      case 'closed':
        return 'Resolved';
      case 'reopened':
        return 'Reopened';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Resolved':
        return const Color(0xFF237A3B);
      case 'In progress':
        return const Color(0xFF185ABC);
      default:
        return const Color(0xFF9A5700);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: DojoPartnerTheme.background,
      appBar: AppBar(title: const Text('DOJO Support')),
      body: user == null
          ? const Center(child: Text('Please log in to view support.'))
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _buildForm(),
                const SizedBox(height: 24),
                const Text(
                  'YOUR SUPPORT REQUESTS',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                    color: DojoPartnerTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildHistory(user.uid),
              ],
            ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DojoPartnerTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How can we help?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: DojoPartnerTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tell us what happened. Please do not include Aadhaar, PAN, OTP or payment credentials.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: DojoPartnerTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Issue category',
              border: OutlineInputBorder(),
            ),
            items: _categories
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: _sending
                ? null
                : (value) {
                    if (value != null) setState(() => _category = value);
                  },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _messageController,
            enabled: !_sending,
            minLines: 3,
            maxLines: 5,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Describe your issue',
              hintText: 'Add details that will help our team assist you...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sending ? null : _submitRequest,
              style: FilledButton.styleFrom(
                backgroundColor: DojoPartnerTheme.primaryOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_sending ? 'Submitting...' : 'Submit Request'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('support_requests')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _historyMessage(
            'Unable to load support history. Pull down to retry.',
            icon: Icons.cloud_off_outlined,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(28),
            child: Center(
              child: CircularProgressIndicator(
                color: DojoPartnerTheme.primaryOrange,
              ),
            ),
          );
        }
        final docs = snapshot.data?.docs.toList() ?? [];
        docs.sort((a, b) {
          final aDate = a.data()['createdAt'];
          final bDate = b.data()['createdAt'];
          final aMillis = aDate is Timestamp ? aDate.millisecondsSinceEpoch : 0;
          final bMillis = bDate is Timestamp ? bDate.millisecondsSinceEpoch : 0;
          return bMillis.compareTo(aMillis);
        });

        if (docs.isEmpty) {
          return _historyMessage(
            'No support requests yet. Your submitted requests will appear here.',
            icon: Icons.inbox_outlined,
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final status = _statusLabel(data['status']);
            final category = (data['category'] ?? 'General').toString();
            final message = (data['message'] ?? '').toString();
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: DojoPartnerTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: DojoPartnerTheme.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _statusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: DojoPartnerTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _dateLabel(data['createdAt']),
                    style: const TextStyle(
                      fontSize: 11,
                      color: DojoPartnerTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _historyMessage(String message, {required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: DojoPartnerTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: DojoPartnerTheme.textSecondary),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: DojoPartnerTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
