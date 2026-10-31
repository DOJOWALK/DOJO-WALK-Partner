import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../account/account_status_presentation.dart';

class KycStatusScreen extends StatefulWidget {
  const KycStatusScreen({super.key});

  @override
  State<KycStatusScreen> createState() => _KycStatusScreenState();
}

class _KycStatusScreenState extends State<KycStatusScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _walker;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Your session has expired. Please log in again.';
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid)
          .get();

      if (!mounted) return;
      setState(() {
        _walker = snapshot.data();
        _loading = false;
        if (!snapshot.exists) {
          _error = 'Partner profile was not found.';
        }
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.code == 'permission-denied'
            ? 'You do not have permission to view these details.'
            : 'Unable to load KYC status. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load KYC status. Please try again.';
      });
    }
  }

  Map<String, dynamic> get _kyc {
    final value = _walker?['kyc'];
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  Map<String, dynamic> get _documents {
    final value = _kyc['documents'];
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  String _accountStatus() {
    return AccountStatusPresentation.fromData(
      _walker ?? <String, dynamic>{},
    ).label;
  }

  String _documentState(String key) {
    final value = _documents[key];
    if (value is! Map) return 'Not uploaded';
    final path = value['storagePath'];
    if (path is! String || path.trim().isEmpty) return 'Not uploaded';

    final status = (value['status'] ?? 'submitted').toString().toLowerCase();
    switch (status) {
      case 'approved':
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Needs correction';
      case 'pending':
      case 'under_review':
        return 'Submitted — review pending';
      default:
        return 'Submitted';
    }
  }

  String _selfieState() {
    final selfie = _kyc['selfie'];
    if (selfie is! Map) return 'Not uploaded';
    final path = selfie['storagePath'];
    if (path is! String || path.trim().isEmpty) return 'Not uploaded';
    final status = (selfie['status'] ?? 'submitted').toString().toLowerCase();
    if (status == 'approved' || status == 'verified') return 'Verified';
    if (status == 'rejected') return 'Needs correction';
    return 'Submitted — review pending';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoPartnerTheme.background,
      appBar: AppBar(title: const Text('Documents & KYC')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: DojoPartnerTheme.primaryOrange,
              ),
            )
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: DojoPartnerTheme.primaryOrange,
                  onRefresh: _loadStatus,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _statusCard(),
                      const SizedBox(height: 22),
                      const Text(
                        'DOCUMENT CHECKLIST',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                          color: DojoPartnerTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _documentTile('Aadhaar Card — Front', _documentState('aadhaar_front')),
                      _documentTile('Aadhaar Card — Back', _documentState('aadhaar_back')),
                      _documentTile('PAN Card', _documentState('pan_card')),
                      _documentTile('Live Selfie', _selfieState()),
                      const SizedBox(height: 16),
                      const Text(
                        'This page shows submission status only. It does not display or download your identity documents.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: DojoPartnerTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: DojoPartnerTheme.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadStatus,
              style: FilledButton.styleFrom(
                backgroundColor: DojoPartnerTheme.primaryOrange,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard() {
    final status = _accountStatus();
    final approved = status == 'Approved & active';
    final restricted = {
      'Correction required',
      'Application not approved',
      'Account suspended',
      'Account closed',
      'Account inactive',
      'Account status needs review — contact support',
    }.contains(status);

    final foreground = approved
        ? const Color(0xFF237A3B)
        : restricted
            ? const Color(0xFFB3261E)
            : const Color(0xFF9A5700);
    final background = approved
        ? const Color(0xFFEAF8EE)
        : restricted
            ? const Color(0xFFFCE8E6)
            : const Color(0xFFFFF3E0);

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
            'APPLICATION STATUS',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
              color: DojoPartnerTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            approved
                ? 'Your account is approved and active.'
                : correction
                    ? 'Please contact DOJO Support for the next steps. Do not upload documents again unless requested.'
                    : 'Your submitted information is shown below. Verification decisions are made by the DOJO review team.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: DojoPartnerTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentTile(String title, String state) {
    final uploaded = state != 'Not uploaded';
    final verified = state == 'Verified';
    final color = verified
        ? const Color(0xFF237A3B)
        : uploaded
            ? const Color(0xFF9A5700)
            : DojoPartnerTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DojoPartnerTheme.border),
      ),
      child: Row(
        children: [
          Icon(
            verified
                ? Icons.verified_outlined
                : uploaded
                    ? Icons.hourglass_top_rounded
                    : Icons.upload_file_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              state,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
