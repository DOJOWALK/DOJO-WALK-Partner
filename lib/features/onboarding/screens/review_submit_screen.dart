
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';

class ReviewSubmitScreen extends StatefulWidget {
  const ReviewSubmitScreen({super.key});

  @override
  State<ReviewSubmitScreen> createState() =>
      _ReviewSubmitScreenState();
}

class _ReviewSubmitScreenState extends State<ReviewSubmitScreen> {
  bool _loading = true;
  bool _submitting = false;
  bool _agreed = false;

  Map<String, dynamic>? _walkerData;

  @override
  void initState() {
    super.initState();
    _loadWalkerData();
  }

  Future<void> _loadWalkerData() async {
    if (mounted) setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      setState(() {
        _walkerData = snapshot.data();
        _loading = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage(
        e.code == 'permission-denied'
            ? 'Access denied. Please check Firestore rules.'
            : 'Unable to load details. Please try again.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Unable to load details. Please try again.');
    }
  }

  String _value(String key) {
    final value = _walkerData?[key];
    if (value == null || value.toString().trim().isEmpty) {
      return 'Not provided';
    }
    return value.toString().trim();
  }

  dynamic _nested(List<String> keys) {
    dynamic current = _walkerData;
    for (final key in keys) {
      if (current is Map) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  String _documentStatus(String key) {
    final doc = _nested(['kyc', 'documents', key]);
    if (doc is Map && doc['storagePath'] is String) {
      return doc['status']?.toString() ?? 'pending';
    }
    return 'not_submitted';
  }

  List<String> _zoneNames() {
    final raw = _walkerData?['zoneNames'];

    if (raw is List) {
      final names = raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      if (names.isNotEmpty) return names;
    }

    final legacy = _walkerData?['zoneName']?.toString().trim();
    if (legacy != null && legacy.isNotEmpty) return [legacy];

    return [];
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'verified':
      case 'completed':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      case 'under_review':
        return 'Under review';
      case 'pending':
        return 'Pending review';
      case 'not_started':
      case 'not_submitted':
      case 'not submitted':
      case '':
        return 'Not submitted';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  bool _isVerified(String status) {
    return ['approved', 'verified', 'completed']
        .contains(status.toLowerCase());
  }

  bool _hasDocument(String key) {
    final doc = _nested(['kyc', 'documents', key]);
    return doc is Map &&
        doc['storagePath'] is String &&
        (doc['storagePath'] as String).isNotEmpty;
  }

  Future<void> _submitApplication() async {
    if (!_agreed) {
      _showMessage('Please confirm that your information is correct.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Session expired. Please log in again.');
      return;
    }

    final data = _walkerData;
    if (data == null ||
        (data['fullName']?.toString().trim().isEmpty ?? true) ||
        (data['phone']?.toString().trim().isEmpty ?? true) ||
        (data['state']?.toString().trim().isEmpty ?? true) ||
        (data['city']?.toString().trim().isEmpty ?? true) ||
        (data['area']?.toString().trim().isEmpty ?? true) ||
        _zoneNames().isEmpty) {
      _showMessage(
        'Please complete your personal details and work location first.',
      );
      return;
    }

    final selfie = _nested(['kyc', 'selfie']);
    if (selfie is! Map ||
        selfie['storagePath'] is! String ||
        (selfie['storagePath'] as String).isEmpty) {
      _showMessage('Please capture and upload your selfie first.');
      return;
    }

    if (!_hasDocument('aadhaar_front') ||
        !_hasDocument('aadhaar_back') ||
        !_hasDocument('pan_card')) {
      _showMessage(
        'Please upload Aadhaar front, Aadhaar back and PAN card first.',
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid)
          .set({
        'userId': user.uid,
        'walkerId': user.uid,
        'status': 'under_review',
        'isActive': false,
        'isApproved': false,
        'verificationStatus': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const ApplicationSubmittedScreen(),
        ),
        (route) => false,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(
        e.code == 'permission-denied'
            ? 'Submission denied. Please check Firestore rules.'
            : 'Submission failed. Please try again.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage('Something went wrong. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  color: DojoPartnerTheme.primaryOrange, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: DojoPartnerTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: DojoPartnerTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DojoPartnerTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationRow(String title, String rawStatus) {
    final verified = _isVerified(rawStatus);
    final submitted = rawStatus.toLowerCase() != 'not_submitted';
    final color = verified
        ? const Color(0xFF23834B)
        : rawStatus.toLowerCase() == 'rejected'
            ? Colors.red
            : DojoPartnerTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: verified
            ? const Color(0xFFF0FAF3)
            : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: verified
              ? const Color(0xFFD5EEDC)
              : const Color(0xFFEEEEEE),
        ),
      ),
      child: Row(
        children: [
          Icon(
            verified
                ? Icons.check_circle_rounded
                : submitted
                    ? Icons.hourglass_empty_rounded
                    : Icons.upload_file_outlined,
            size: 21,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DojoPartnerTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _statusLabel(rawStatus).toUpperCase(),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Review & Submit'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: DojoPartnerTheme.primaryOrange,
                ),
              )
            : _walkerData == null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: DojoPartnerTheme.textSecondary),
            const SizedBox(height: 14),
            const Text(
              'Unable to load your application.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadWalkerData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final zones = _zoneNames();
    final selfieStatus = _nested(['kyc', 'selfie', 'status']);
    final selfiePath = _nested(['kyc', 'selfie', 'storagePath']);
    final selfie = selfiePath is String && selfiePath.isNotEmpty
        ? (selfieStatus?.toString() ?? 'pending')
        : 'not_submitted';

    return Column(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  const Center(
                    child: Icon(Icons.fact_check_outlined,
                        size: 44, color: DojoPartnerTheme.primaryOrange),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Review your application',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: DojoPartnerTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please check your details before submitting.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: DojoPartnerTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _section(
                    title: 'Personal Details',
                    icon: Icons.person_outline_rounded,
                    children: [
                      _row('Full Name', _value('fullName')),
                      _row('Phone', _value('phone')),
                    ],
                  ),
                  _section(
                    title: 'Work Location',
                    icon: Icons.location_on_outlined,
                    children: [
                      _row('State', _value('state')),
                      _row('City', _value('city')),
                      _row('Area / Locality', _value('area')),
                      _row(
                        'Selected Zones',
                        zones.isEmpty ? 'Not provided' : zones.join(', '),
                      ),
                    ],
                  ),
                  _section(
                    title: 'KYC & Verification',
                    icon: Icons.verified_user_outlined,
                    children: [
                      _verificationRow(
                        'Aadhaar Front',
                        _documentStatus('aadhaar_front'),
                      ),
                      _verificationRow(
                        'Aadhaar Back',
                        _documentStatus('aadhaar_back'),
                      ),
                      _verificationRow(
                        'PAN Card',
                        _documentStatus('pan_card'),
                      ),
                      _verificationRow('Selfie', selfie),
                      const SizedBox(height: 4),
                      const Text(
                        'Documents are submitted for review. A pending status does not mean they are verified.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: DojoPartnerTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFDFC4)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: DojoPartnerTheme.primaryOrange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'DOJO will review your application. You cannot accept walks until your Partner account is approved and activated.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: DojoPartnerTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _submitting
                        ? null
                        : () => setState(() => _agreed = !_agreed),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _agreed
                              ? DojoPartnerTheme.primaryOrange
                              : const Color(0xFFE5E5E5),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreed,
                            activeColor: DojoPartnerTheme.primaryOrange,
                            onChanged: _submitting
                                ? null
                                : (value) => setState(
                                      () => _agreed = value ?? false,
                                    ),
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 12, right: 4),
                              child: Text(
                                'I confirm that my information is correct and agree to DOJO reviewing my Partner application.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: DojoPartnerTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE8E8E8))),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DojoPartnerTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Application',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ApplicationSubmittedScreen extends StatelessWidget {
  const ApplicationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 88,
                    width: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8EE),
                      borderRadius: BorderRadius.circular(44),
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 48, color: Color(0xFF23834B)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Application Submitted',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: DojoPartnerTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your DOJO Partner application has been submitted for review.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: DojoPartnerTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E5E5)),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'APPLICATION STATUS',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: DojoPartnerTheme.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'UNDER REVIEW',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: DojoPartnerTheme.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'DOJO will review your details. You can accept walks only after your Partner account is approved and activated.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: DojoPartnerTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
