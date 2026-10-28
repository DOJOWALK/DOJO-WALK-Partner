import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../theme.dart';
import 'current_address_screen.dart';

class KycDocumentsScreen extends StatefulWidget {
  const KycDocumentsScreen({super.key});

  @override
  State<KycDocumentsScreen> createState() =>
      _KycDocumentsScreenState();
}

class _KycDocumentsScreenState extends State<KycDocumentsScreen> {
  final ImagePicker _picker = ImagePicker();

  final Map<String, File?> _documents = {
    'aadhaar_front': null,
    'aadhaar_back': null,
    'pan_card': null,
  };

  final Map<String, String> _labels = {
    'aadhaar_front': 'Aadhaar Card — Front',
    'aadhaar_back': 'Aadhaar Card — Back',
    'pan_card': 'PAN Card',
  };

  final Map<String, String> _storagePaths = {};

  String? _activeKey;

  bool _isUploading = false;
  double _uploadProgress = 0;
  String _uploadMessage = '';

  int get _completedCount =>
      _documents.values.where((file) => file != null).length;

  Future<void> _captureDocument(String key) async {
    if (_activeKey != null || _isUploading) return;

    setState(() => _activeKey = key);

    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 2000,
      );

      if (!mounted || image == null) return;

      final file = File(image.path);

      if (!await file.exists()) {
        _showMessage(
          'Photo could not be saved. Please capture it again.',
        );
        return;
      }

      final length = await file.length();

      if (length == 0) {
        _showMessage(
          'The captured photo is empty. Please try again.',
        );
        return;
      }

      setState(() {
        _documents[key] = file;
      });
    } catch (e) {
      debugPrint('Document capture error: $e');

      if (mounted) {
        _showMessage(
          'Camera could not open. Please check camera permission.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _activeKey = null);
      }
    }
  }

  Future<void> _uploadDocuments() async {
    if (_isUploading || _activeKey != null) return;

    final missing = _documents.entries
        .where((entry) => entry.value == null)
        .map((entry) => _labels[entry.key]!)
        .toList();

    if (missing.isNotEmpty) {
      _showMessage(
        'Please capture all three required documents first.',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Your session expired. Please log in again.',
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadMessage = 'Preparing documents...';
    });

    try {
      final walkerRef = FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid);

      final walkerSnapshot = await walkerRef.get();

      if (!walkerSnapshot.exists) {
        throw Exception(
          'Partner profile not found. Please complete personal details first.',
        );
      }

      const documentKeys = [
        'aadhaar_front',
        'aadhaar_back',
        'pan_card',
      ];

      final documentRecords = <String, dynamic>{};

      for (var i = 0; i < documentKeys.length; i++) {
        final key = documentKeys[i];
        final file = _documents[key]!;

        if (!await file.exists()) {
          throw Exception(
            '${_labels[key]} photo is missing. Please capture it again.',
          );
        }

        final fileSize = await file.length();

        if (fileSize == 0) {
          throw Exception(
            '${_labels[key]} photo is empty. Please capture it again.',
          );
        }

        if (!mounted) return;

        setState(() {
          _uploadMessage = 'Uploading ${_labels[key]}...';
          _uploadProgress = i / documentKeys.length;
        });

        // Reuse an existing Storage path only when this screen
        // already uploaded that document during this session.
        String storagePath = _storagePaths[key] ?? '';

        if (storagePath.isEmpty) {
          final timestamp =
              DateTime.now().millisecondsSinceEpoch;

          storagePath =
              'walker_kyc/${user.uid}/${key}_$timestamp.jpg';
        }

        final storageRef =
            FirebaseStorage.instance.ref().child(storagePath);

        await storageRef.putFile(
          file,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'userId': user.uid,
              'documentType': key,
            },
          ),
        );

        _storagePaths[key] = storagePath;

        documentRecords[key] = {
          'status': 'pending',
          'storagePath': storagePath,
          'submittedAt': FieldValue.serverTimestamp(),
        };

        if (mounted) {
          setState(() {
            _uploadProgress = (i + 1) / documentKeys.length;
          });
        }
      }

      if (!mounted) return;

      setState(() {
        _uploadMessage = 'Saving verification details...';
      });

      await walkerRef.set(
        {
          'userId': user.uid,
          'kyc': {
            'documents': documentRecords,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const CurrentAddressScreen(),
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'KYC upload Firebase error: ${e.code} ${e.message}',
      );

      if (!mounted) return;

      String message;

      if (e.code == 'permission-denied' ||
          e.code == 'unauthorized') {
        message =
            'Firebase access denied. Please check Storage and Firestore security rules.';
      } else if (e.code == 'object-not-found') {
        message =
            'A document could not be found. Please try uploading again.';
      } else if (e.code == 'network-request-failed') {
        message =
            'Network error. Check your internet connection and retry.';
      } else {
        message = e.message ?? 'Unable to upload documents.';
      }

      _showMessage(message);
    } catch (e) {
      debugPrint('KYC upload error: $e');

      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadMessage = '';
        });
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

  Widget _documentCard(String key) {
    final file = _documents[key];
    final isActive = _activeKey == key;
    final isReady = file != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isReady
              ? DojoPartnerTheme.primaryOrange
              : const Color(0xFFE7E7E7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isReady
                      ? const Color(0xFFFFF0E4)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isReady
                      ? Icons.check_circle_rounded
                      : Icons.description_outlined,
                  color: isReady
                      ? DojoPartnerTheme.primaryOrange
                      : DojoPartnerTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _labels[key]!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: DojoPartnerTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isReady
                          ? 'Photo captured successfully'
                          : 'Photo required',
                      style: const TextStyle(
                        fontSize: 12,
                        color: DojoPartnerTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isReady)
                const Text(
                  'READY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: DojoPartnerTheme.primaryOrange,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: DojoPartnerTheme.primaryOrange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isReady
                        ? 'Photo saved locally. Upload it securely to continue.'
                        : 'Capture a clear photo with all document edges visible.',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: DojoPartnerTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _activeKey != null || _isUploading
                  ? null
                  : () => _captureDocument(key),
              icon: isActive
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      isReady
                          ? Icons.refresh_rounded
                          : Icons.camera_alt_outlined,
                    ),
              label: Text(
                isActive
                    ? 'Opening Camera...'
                    : isReady
                        ? 'Retake Photo'
                        : 'Capture Document',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: DojoPartnerTheme.primaryOrange,
                side: const BorderSide(
                  color: DojoPartnerTheme.primaryOrange,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completedCount;

    return Scaffold(
      backgroundColor: const DojoPartnerTheme.background,
      appBar: AppBar(
        title: const Text('KYC Documents'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Verify your documents',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: DojoPartnerTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Capture clear photos of your original documents. '
                    'You can review the photos later before final submission.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: DojoPartnerTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: completed / 3,
                            minHeight: 6,
                            color: DojoPartnerTheme.primaryOrange,
                            backgroundColor:
                                const Color(0xFFEAEAEA),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$completed of 3',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _documentCard('aadhaar_front'),
                  const SizedBox(height: 14),
                  _documentCard('aadhaar_back'),
                  const SizedBox(height: 14),
                  _documentCard('pan_card'),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7F0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFDFC4),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: DojoPartnerTheme.primaryOrange,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your identity documents contain sensitive '
                            'information. Access should be limited to '
                            'authorized personnel through Firebase security rules.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE8E8E8),
                  ),
                ),
              ),
              child: Column(
                children: [
                  if (_isUploading) ...[
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      color: DojoPartnerTheme.primaryOrange,
                      backgroundColor: const Color(0xFFEAEAEA),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _uploadMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: completed == 3 &&
                              _activeKey == null &&
                              !_isUploading
                          ? _uploadDocuments
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            DojoPartnerTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const DojoPartnerTheme.border,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: _isUploading
                          ? const Text('Uploading Documents...')
                          : const Text(
                              'Upload & Continue',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
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
