
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme.dart';
import 'kyc_documents_screen.dart';

class LiveSelfieScreen extends StatefulWidget {
  const LiveSelfieScreen({super.key});

  @override
  State<LiveSelfieScreen> createState() => _LiveSelfieScreenState();
}

class _LiveSelfieScreenState extends State<LiveSelfieScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _selfieFile;
  bool _isCapturing = false;
  bool _isUploading = false;

  Future<void> _captureSelfie() async {
    if (_isCapturing || _isUploading) return;

    setState(() => _isCapturing = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (!mounted) return;

      if (image != null) {
        setState(() {
          _selfieFile = File(image.path);
        });
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to open the camera. Please check camera permission.',
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _confirmSelfie() async {
    if (_selfieFile == null) {
      _showMessage('Please take your selfie first.');
      return;
    }

    if (_isUploading || _isCapturing) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Your session expired. Please log in again.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final storagePath =
          'walker_selfies/${user.uid}/selfie_$timestamp.jpg';

      final storageRef =
          FirebaseStorage.instance.ref().child(storagePath);

      await storageRef.putFile(
        _selfieFile!,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'walkerId': user.uid,
            'documentType': 'selfie',
          },
        ),
      );

      await FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid)
          .set(
        {
          'userId': user.uid,
          'walkerId': user.uid,
          'kyc': {
            'selfie': {
              'status': 'pending',
              'storagePath': storagePath,
              'submittedAt': FieldValue.serverTimestamp(),
            },
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const KycDocumentsScreen(),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      String message;

      if (e.code == 'permission-denied' ||
          e.code == 'unauthorized') {
        message =
            'Access denied. Please check Firebase Storage and Firestore rules.';
      } else {
        message = e.message ?? 'Unable to upload your selfie.';
      }

      _showMessage(message);
    } catch (_) {
      if (!mounted) return;

      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildSelfiePreview() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE7E7E7),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 210,
            height: 210,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF1E5),
              border: Border.all(
                color: DojoPartnerTheme.primaryOrange,
                width: 3,
              ),
            ),
            child: _selfieFile == null
                ? const Icon(
                    Icons.person_outline_rounded,
                    size: 100,
                    color: DojoPartnerTheme.primaryOrange,
                  )
                : Image.file(
                    _selfieFile!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      size: 60,
                      color: DojoPartnerTheme.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Text(
            _selfieFile == null
                ? 'Your selfie will appear here'
                : 'Selfie captured',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: DojoPartnerTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _selfieFile == null
                ? 'Use the front camera to take a clear photo.'
                : 'Check your photo before confirming.',
            textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    final busy = _isCapturing || _isUploading;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Selfie Verification'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      22,
                      24,
                      22,
                      24,
                    ),
                    children: [
                      const Center(
                        child: Text(
                          'DOJO PARTNER',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: DojoPartnerTheme.primaryOrange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Verify your identity',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: DojoPartnerTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Take a clear photo of your face. '
                        'DOJO will review your submission.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: DojoPartnerTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 26),
                      _buildSelfiePreview(),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5EC),
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
                            SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                'Use good lighting, face the camera '
                                'directly and remove anything covering '
                                'your face.',
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
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    14,
                    22,
                    18,
                  ),
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
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : _captureSelfie,
                          icon: _isCapturing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _selfieFile == null
                                      ? Icons.camera_alt_outlined
                                      : Icons.refresh_rounded,
                                ),
                          label: Text(
                            _isCapturing
                                ? 'Opening Camera...'
                                : _selfieFile == null
                                    ? 'Take Selfie'
                                    : 'Retake Selfie',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                DojoPartnerTheme.primaryOrange,
                            side: const BorderSide(
                              color: DojoPartnerTheme.primaryOrange,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed:
                              busy || _selfieFile == null
                                  ? null
                                  : _confirmSelfie,
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
                              ? const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text('Uploading Selfie...'),
                                  ],
                                )
                              : const Text(
                                  'Confirm Selfie & Continue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
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
        ),
      ),
    );
  }
}
