import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
    if (mounted) {
      setState(() => _loading = true);
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Your session expired. Please log in again.');
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
            : 'Unable to load your details. Please try again.',
      );
    } catch (e) {
      debugPrint('Load review data error: $e');

      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Unable to load your details. Please try again.');
    }
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

  String _value(String key) {
    final value = _walkerData?[key];

    if (value == null || value.toString().trim().isEmpty) {
      return 'Not provided';
    }

    return value.toString().trim();
  }

  String _addressValue(String key) {
    final value = _nested(['currentAddress', key]);

    if (value == null || value.toString().trim().isEmpty) {
      return 'Not provided';
    }

    return value.toString().trim();
  }

  String _documentPath(String key) {
    final path = _nested([
      'kyc',
      'documents',
      key,
      'storagePath',
    ]);

    return path is String ? path.trim() : '';
  }

  String _selfiePath() {
    final path = _nested(['kyc', 'selfie', 'storagePath']);

    return path is String ? path.trim() : '';
  }

  String _documentStatus(String key) {
    final path = _documentPath(key);

    if (path.isEmpty) return 'not_submitted';

    final status = _nested([
      'kyc',
      'documents',
      key,
      'status',
    ]);

    return status?.toString() ?? 'pending';
  }

  String _selfieStatus() {
    if (_selfiePath().isEmpty) return 'not_submitted';

    final status = _nested(['kyc', 'selfie', 'status']);

    return status?.toString() ?? 'pending';
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

    if (legacy != null && legacy.isNotEmpty) {
      return [legacy];
    }

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
    return [
      'approved',
      'verified',
      'completed',
    ].contains(status.toLowerCase());
  }

  bool _hasCompleteAddress() {
    final requiredFields = [
      'houseNumber',
      'street',
      'city',
      'state',
      'pinCode',
    ];

    for (final field in requiredFields) {
      if (_addressValue(field) == 'Not provided') {
        return false;
      }
    }

    return true;
  }

  bool _hasCompleteWorkLocation() {
    return _value('state') != 'Not provided' &&
        _value('city') != 'Not provided' &&
        _value('area') != 'Not provided' &&
        _zoneNames().isNotEmpty;
  }

  bool _hasRequiredDocuments() {
    return _documentPath('aadhaar_front').isNotEmpty &&
        _documentPath('aadhaar_back').isNotEmpty &&
        _documentPath('pan_card').isNotEmpty &&
        _selfiePath().isNotEmpty;
  }

  Future<void> _viewPhoto({
    required String title,
    required String storagePath,
  }) async {
    if (storagePath.trim().isEmpty) {
      _showMessage('This photo has not been uploaded yet.');
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: SizedBox(
            height: 480,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: DojoPartnerTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<Uint8List>(
                    future: FirebaseStorage.instance
                        .ref()
                        .child(storagePath)
                        .getData(10 * 1024 * 1024)
                        .then((data) {
                      if (data == null || data.isEmpty) {
                        throw Exception('Photo data is empty.');
                      }

                      return data;
                    }),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: DojoPartnerTheme.primaryOrange,
                          ),
                        );
                      }

                      if (snapshot.hasError ||
                          !snapshot.hasData) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: DojoPartnerTheme.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Unable to load this photo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Check Firebase Storage permissions and confirm that the file exists.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: DojoPartnerTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      }

                      return InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4,
                        child: Center(
                          child: Image.memory(
                            snapshot.data!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'The uploaded file is not a valid image.',
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(),
                      child: const Text('Close Photo'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Keep local references intentionally available for callers.
    // The photo dialog closes independently of the review screen.
    if (!mounted) return;

    // Avoid using getDownloadURL: this screen reads the private
    // Storage object directly through its authenticated reference.
    // These references are only used if later error handling is added.
    assert(navigator.mounted);
    assert(messenger.mounted);
  }

  Future<void> _submitApplication() async {
    if (_submitting) return;

    if (!_agreed) {
      _showMessage(
        'Please confirm that your information is correct.',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Your session expired. Please log in again.');
      return;
    }

    final data = _walkerData;

    if (data == null) {
      _showMessage('Unable to load your application details.');
      return;
    }

    if (_value('fullName') == 'Not provided' ||
        _value('phone') == 'Not provided') {
      _showMessage(
        'Please complete your personal details first.',
      );
      return;
    }

    if (!_hasCompleteWorkLocation()) {
      _showMessage(
        'Please complete your work location and selected zones first.',
      );
      return;
    }

    if (!_hasCompleteAddress()) {
      _showMessage(
        'Please complete your current residential address first.',
      );
      return;
    }

    if (!_hasRequiredDocuments()) {
      _showMessage(
        'Please upload your selfie, Aadhaar front, Aadhaar back and PAN card first.',
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final walkerRef = FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid);

      // Re-read the document to avoid submitting based solely
      // on stale data displayed by this screen.
      final latestSnapshot = await walkerRef.get();

      if (!latestSnapshot.exists) {
        throw Exception('Partner profile not found.');
      }

      final latestData = latestSnapshot.data() ?? {};

      final selfie = latestData['kyc'] is Map
          ? (latestData['kyc'] as Map)['selfie']
          : null;

      final documents = latestData['kyc'] is Map
          ? (latestData['kyc'] as Map)['documents']
          : null;

      bool hasPath(dynamic record) {
        return record is Map &&
            record['storagePath'] is String &&
            (record['storagePath'] as String).trim().isNotEmpty;
      }

      if (!hasPath(selfie) ||
          documents is! Map ||
          !hasPath(documents['aadhaar_front']) ||
          !hasPath(documents['aadhaar_back']) ||
          !hasPath(documents['pan_card'])) {
        throw Exception(
          'One or more required KYC photos are missing. Please return and upload them again.',
        );
      }

      final latestAddress = latestData['currentAddress'];

      if (latestAddress is! Map) {
        throw Exception(
          'Current residential address is missing.',
        );
      }

      for (final field in [
        'houseNumber',
        'street',
        'city',
        'state',
        'pinCode',
      ]) {
        final value = latestAddress[field];

        if (value == null || value.toString().trim().isEmpty) {
          throw Exception(
            'Please complete your current residential address first.',
          );
        }
      }

      final zones = latestData['zoneNames'];
      final legacyZone = latestData['zoneName'];

      final hasZones =
          (zones is List &&
              zones.any((e) => e.toString().trim().isNotEmpty)) ||
          (legacyZone is String && legacyZone.trim().isNotEmpty);

      if (!hasZones) {
        throw Exception(
          'Please select at least one work zone.',
        );
      }

      await walkerRef.set(
        {
          'userId': user.uid,
          'status': 'under_review',
          'isActive': false,
          'isApproved': false,
          'verificationStatus': 'pending',
          'submittedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const ApplicationSubmittedScreen(),
        ),
        (route) => false,
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'Submit application Firebase error: ${e.code}',
      );

      if (!mounted) return;

      _showMessage(
        e.code == 'permission-denied'
            ? 'Submission denied. Please check Firestore rules.'
            : e.code == 'network-request-failed'
                ? 'Network error. Please check your connection.'
                : e.message ?? 'Submission failed. Please try again.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
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
              Icon(
                icon,
                color: DojoPartnerTheme.primaryOrange,
                size: 22,
              ),
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

  Widget _photoRow({
    required String title,
    required String path,
    required String status,
  }) {
    final hasPhoto = path.isNotEmpty;
    final verified = _isVerified(status);

    final color = verified
        ? const Color(0xFF23834B)
        : status.toLowerCase() == 'rejected'
            ? Colors.red
            : DojoPartnerTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPhoto
                    ? Icons.check_circle_outline_rounded
                    : Icons.upload_file_outlined,
                size: 21,
                color: hasPhoto
                    ? DojoPartnerTheme.primaryOrange
                    : DojoPartnerTheme.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DojoPartnerTheme.textPrimary,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  _statusLabel(status).toUpperCase(),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: hasPhoto && !_submitting
                  ? () => _viewPhoto(
                        title: title,
                        storagePath: path,
                      )
                  : null,
              icon: const Icon(
                Icons.visibility_outlined,
                size: 19,
              ),
              label: const Text('View Photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DojoPartnerTheme.primaryOrange,
                disabledForegroundColor: Colors.grey,
                side: const BorderSide(
                  color: DojoPartnerTheme.primaryOrange,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (!hasPhoto) ...[
            const SizedBox(height: 6),
            const Text(
              'Photo not uploaded. Return to the KYC step to complete it.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.red,
              ),
            ),
          ],
        ],
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
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: DojoPartnerTheme.textSecondary,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load your application.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
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
                    child: Icon(
                      Icons.fact_check_outlined,
                      size: 44,
                      color: DojoPartnerTheme.primaryOrange,
                    ),
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
                    'Check your details and documents before submitting.',
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
                      _row('Email', _value('email')),
                      _row('Date of Birth', _value('dateOfBirth')),
                      _row('Gender', _value('gender')),
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
                        zones.isEmpty
                            ? 'Not provided'
                            : zones.join(', '),
                      ),
                    ],
                  ),

                  _section(
                    title: 'Current Residential Address',
                    icon: Icons.home_work_outlined,
                    children: [
                      _row(
                        'House / Flat',
                        _addressValue('houseNumber'),
                      ),
                      _row(
                        'Street / Locality',
                        _addressValue('street'),
                      ),
                      _row(
                        'Landmark',
                        _addressValue('landmark'),
                      ),
                      _row(
                        'City',
                        _addressValue('city'),
                      ),
                      _row(
                        'State',
                        _addressValue('state'),
                      ),
                      _row(
                        'PIN Code',
                        _addressValue('pinCode'),
                      ),
                    ],
                  ),

                  _section(
                    title: 'KYC Documents',
                    icon: Icons.verified_user_outlined,
                    children: [
                      _photoRow(
                        title: 'Aadhaar Card — Front',
                        path: _documentPath('aadhaar_front'),
                        status: _documentStatus('aadhaar_front'),
                      ),
                      _photoRow(
                        title: 'Aadhaar Card — Back',
                        path: _documentPath('aadhaar_back'),
                        status: _documentStatus('aadhaar_back'),
                      ),
                      _photoRow(
                        title: 'PAN Card',
                        path: _documentPath('pan_card'),
                        status: _documentStatus('pan_card'),
                      ),
                      _photoRow(
                        title: 'Live Selfie',
                        path: _selfiePath(),
                        status: _selfieStatus(),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pending means submitted for review, not verified. DOJO must complete verification before activation.',
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
                      border: Border.all(
                        color: const Color(0xFFFFDFC4),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: DojoPartnerTheme.primaryOrange,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your application will be reviewed by DOJO. You cannot accept walks until your Partner account is approved and activated.',
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
                        : () => setState(
                              () => _agreed = !_agreed,
                            ),
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
                            activeColor:
                                DojoPartnerTheme.primaryOrange,
                            onChanged: _submitting
                                ? null
                                : (value) => setState(
                                      () => _agreed = value ?? false,
                                    ),
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: 12,
                                right: 4,
                              ),
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
            border: Border(
              top: BorderSide(color: Color(0xFFE8E8E8)),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitting
                      ? null
                      : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        DojoPartnerTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
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
                    child: const Icon(
                      Icons.check_rounded,
                      size: 48,
                      color: Color(0xFF23834B),
                    ),
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
                      border: Border.all(
                        color: const Color(0xFFE5E5E5),
                      ),
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
