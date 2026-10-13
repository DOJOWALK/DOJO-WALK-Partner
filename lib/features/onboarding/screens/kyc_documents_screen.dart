import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme.dart';
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

      if (!mounted) return;

      if (image != null) {
        final file = File(image.path);

        if (!await file.exists()) {
          _showMessage(
            'Photo could not be saved. Please capture it again.',
          );
          return;
        }

        setState(() {
          _documents[key] = file;
        });
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Camera could not open. Please check camera permission.',
      );
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
        'Please capture all required documents before continuing.',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Your session expired. Please log in again.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadMessage = 'Preparing documents...';
    });

    final uploadedPaths = <String, String>{};

    try {
      final walkerRef = FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid);

      // This screen updates an existing onboarding profile.
      final walkerSnapshot = await walkerRef.get();

      if (!walkerSnapshot.exists) {
        throw Exception(
          'Partner profile not found. Please complete your '
          'personal details first.',
        );
      }

      const documentKeys = [
        'aadhaar_front',
        'aadhaar_back',
        'pan_card',
      ];

      for (var i = 0; i < documentKeys.length; i++) {
        final key = documentKeys[i];
        final file = _documents[key]!;

        if (!await file.exists()) {
          throw Exception(
            '${_labels[key]} photo is missing. Please capture it again.',
          );
        }

        final fileName =
            '${key}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Private Storage path; no public download URL is generated.
        final storagePath =
            'walker_kyc/${user.uid}/$fileName';

        if (mounted) {
          setState(() {
            _uploadMessage = 'Uploading ${_labels[key]}...';
            _uploadProgress = i / documentKeys.length;
          });
        }

        final ref = FirebaseStorage.instance
            .ref()
            .child(storagePath);

        await ref.putFile(
          file,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'userId': user.uid,
              'documentType': key,
            },
          ),
        );

        uploadedPaths[key] = storagePath;

        if (mounted) {
          setState(() {
            _uploadProgress = (i + 1) / documentKeys.length;
          });
        }
      }

      if (mounted) {
        setState(() {
          _uploadMessage = 'Saving verification details...';
        });
      }

      final documentRecords = <String, dynamic>{};

      for (final entry in uploadedPaths.entries) {
        documentRecords[entry.key] = {
          'status': 'pending',
          'storagePath': entry.value,
          'submittedAt': FieldValue.serverTimestamp(),
        };
      }

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
        MaterialPageRoute(
          builder: (_) => const CurrentAddressScreen(),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      String message;

      if (e.code == 'permission-denied' ||
          e.code == 'unauthorized') {
        message =
            'Firebase access denied. Please check your Storage '
            'and Firestore security rules.';
      } else if (e.code == 'object-not-found') {
        message = 'Uploaded document was not found. Please retry.';
      } else {
        message = e.message ?? 'Unable to upload documents.';
      }

      _showMessage(message);
    } catch (e) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _documentCard(String key) {
    final file = _documents[key];
    final isActive = _activeKey == key;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: file == null
              ? const Color(0xFFE7E7E7)
              : DojoPartnerTheme.primaryOrange,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                file == null
                    ? Icons.description_outlined
                    : Icons.check_circle_rounded,
                color: file == null
                    ? DojoPartnerTheme.textSecondary
                    : DojoPartnerTheme.primaryOrange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _labels[key]!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DojoPartnerTheme.textPrimary,
                  ),
                ),
              ),
              if (file != null)
                const Text(
                  'READY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: DojoPartnerTheme.primaryOrange,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (file != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                file,
                width: double.infinity,
                height: 170,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 110,
                  child: Center(
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 34,
                    color: DojoPartnerTheme.primaryOrange,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Capture a clear document photo',
                    style: TextStyle(
                      fontSize: 12,
                      color: DojoPartnerTheme.textSecondary,
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
                      file == null
                          ? Icons.camera_alt_outlined
                          : Icons.refresh_rounded,
                    ),
              label: Text(
                isActive
                    ? 'Opening Camera...'
                    : file == null
                        ? 'Capture Document'
                        : 'Retake Photo',
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
      backgroundColor: const Color(0xFFFAFAFA),
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
                    'Capture clear, readable photos of your original '
                    'documents. Avoid glare and keep all edges visible.',
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
                            backgroundColor: const Color(0xFFEAEAEA),
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
                          Icons.lock_outline_rounded,
                          color: DojoPartnerTheme.primaryOrange,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your documents contain sensitive personal '
                            'information. Upload only your own documents. '
                            'Access must be restricted by Firebase rules.',
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
                  top: BorderSide(color: Color(0xFFE8E8E8)),
                ),
              ),
              child: Column(
                children: [
                  if (_isUploading) ...[
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      color: DojoPartnerTheme.primaryOrange,
                    ),
                    const SizedBox(height: 8),
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
                            const Color(0xFFE5E5E5),
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
