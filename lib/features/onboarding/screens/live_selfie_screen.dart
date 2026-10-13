import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../../theme.dart';
import 'kyc_documents_screen.dart';

class LiveSelfieScreen extends StatefulWidget {
  const LiveSelfieScreen({super.key});

  @override
  State<LiveSelfieScreen> createState() => _LiveSelfieScreenState();
}

class _LiveSelfieScreenState extends State<LiveSelfieScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  FaceDetector? _faceDetector;

  File? _selfieFile;

  bool _initializing = true;
  bool _processingFrame = false;
  bool _capturing = false;
  bool _uploading = false;
  bool _cameraReady = false;
  bool _disposed = false;

  String _status = 'Starting camera...';
  String _qualityStatus = 'Waiting for your face';

  int _goodFrames = 0;
  DateTime _lastFrameTime = DateTime.fromMillisecondsSinceEpoch(0);

  static const int _requiredGoodFrames = 8;
  static const double _minFaceWidthRatio = 0.22;
  static const double _maxFaceWidthRatio = 0.78;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableClassification: true,
        enableTracking: true,
        minFaceSize: 0.15,
      ),
    );
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed &&
        mounted &&
        _selfieFile == null &&
        !_uploading) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted || _disposed) return;

    setState(() {
      _initializing = true;
      _cameraReady = false;
      _status = 'Starting front camera...';
      _qualityStatus = 'Waiting for your face';
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No camera is available on this device.');
      }

      CameraDescription selected = cameras.first;
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selected = camera;
          break;
        }
      }

      final oldCamera = _camera;
      _camera = null;

      if (oldCamera != null) {
        await oldCamera.dispose();
      }

      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      _camera = controller;
      await controller.initialize();

      if (!mounted || _disposed) {
        await controller.dispose();
        return;
      }

      setState(() {
        _initializing = false;
        _cameraReady = true;
        _status = 'Position your face inside the frame';
      });

      await controller.startImageStream(_processCameraFrame);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _cameraReady = false;
        _status = 'Camera could not start';
        _qualityStatus = 'Check camera permission and try again.';
      });
    }
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    if (_processingFrame ||
        _capturing ||
        _uploading ||
        _selfieFile != null ||
        _faceDetector == null ||
        _camera == null ||
        !_cameraReady) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastFrameTime).inMilliseconds < 180) return;
    _lastFrameTime = now;
    _processingFrame = true;

    try {
      final camera = _camera!;
      final input = _buildInputImage(image, camera);
      if (input == null) {
        _updateStatus(
          'Camera format not supported',
          'Please restart the app and try again.',
        );
        return;
      }

      final faces = await _faceDetector!.processImage(input);

      if (!mounted || _selfieFile != null || _capturing) return;

      if (faces.length != 1) {
        _goodFrames = 0;
        _updateStatus(
          faces.isEmpty ? 'Face not detected' : 'Only one face is allowed',
          faces.isEmpty
              ? 'Look directly at the front camera.'
              : 'Make sure only your face is visible.',
        );
        return;
      }

      final face = faces.first;
      final box = face.boundingBox;
      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();

      final faceWidthRatio = box.width / imageWidth;
      final centerX = box.center.dx / imageWidth;
      final centerY = box.center.dy / imageHeight;

      final centered = centerX > 0.22 &&
          centerX < 0.78 &&
          centerY > 0.18 &&
          centerY < 0.82;

      final correctSize = faceWidthRatio >= _minFaceWidthRatio &&
          faceWidthRatio <= _maxFaceWidthRatio;

      final eyesVisible = face.leftEyeOpenProbability == null ||
          face.rightEyeOpenProbability == null ||
          (face.leftEyeOpenProbability! > 0.15 &&
              face.rightEyeOpenProbability! > 0.15);

      final headStraight = (face.headEulerAngleY ?? 0).abs() < 18 &&
          (face.headEulerAngleZ ?? 0).abs() < 15;

      if (!centered) {
        _goodFrames = 0;
        _updateStatus(
          'Adjust your face position',
          'Move your face into the centre of the frame.',
        );
        return;
      }

      if (!correctSize) {
        _goodFrames = 0;
        _updateStatus(
          faceWidthRatio < _minFaceWidthRatio
              ? 'Move a little closer'
              : 'Move a little farther away',
          'Keep your full face inside the frame.',
        );
        return;
      }

      if (!eyesVisible) {
        _goodFrames = 0;
        _updateStatus(
          'Eyes not clearly visible',
          'Remove sunglasses or anything covering your eyes.',
        );
        return;
      }

      if (!headStraight) {
        _goodFrames = 0;
        _updateStatus(
          'Face the camera directly',
          'Keep your head straight.',
        );
        return;
      }

      _goodFrames++;
      _updateStatus(
        'Face position looks good',
        'Hold still. Preparing automatic capture...',
      );

      if (_goodFrames >= _requiredGoodFrames) {
        await _captureAutomatically();
      }
    } catch (_) {
      _goodFrames = 0;
      _updateStatus(
        'Checking your face...',
        'Keep your face visible and hold still.',
      );
    } finally {
      _processingFrame = false;
    }
  }

  InputImage? _buildInputImage(
    CameraImage image,
    CameraController controller,
  ) {
    final camera = controller.description;
    final rotation = _rotationForCamera(camera);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final bytes = _convertCameraBytes(image);
    if (bytes == null) return null;

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  InputImageRotation? _rotationForCamera(CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;

    if (Platform.isAndroid) {
      final deviceOrientation = _camera?.value.deviceOrientation;
      final deviceRotation = switch (deviceOrientation) {
        DeviceOrientation.portraitUp => 0,
        DeviceOrientation.landscapeLeft => 90,
        DeviceOrientation.portraitDown => 180,
        DeviceOrientation.landscapeRight => 270,
        _ => 0,
      };

      final adjusted = camera.lensDirection == CameraLensDirection.front
          ? (sensorOrientation + deviceRotation) % 360
          : (sensorOrientation - deviceRotation + 360) % 360;

      return InputImageRotationValue.fromRawValue(adjusted);
    }

    return InputImageRotationValue.fromRawValue(sensorOrientation);
  }

  Uint8List? _convertCameraBytes(CameraImage image) {
    if (image.planes.isEmpty) return null;

    if (Platform.isAndroid && image.planes.length == 1) {
      return image.planes.first.bytes;
    }

    if (image.planes.length == 1) {
      return image.planes.first.bytes;
    }

    // ML Kit expects one byte buffer. Combine planes for supported formats.
    final builder = BytesBuilder(copy: false);
    for (final plane in image.planes) {
      builder.add(plane.bytes);
    }
    return builder.takeBytes();
  }

  void _updateStatus(String status, String quality) {
    if (!mounted) return;
    if (_status == status && _qualityStatus == quality) return;

    setState(() {
      _status = status;
      _qualityStatus = quality;
    });
  }

  Future<void> _captureAutomatically() async {
    final camera = _camera;
    if (camera == null ||
        !camera.value.isInitialized ||
        _capturing ||
        _selfieFile != null) {
      return;
    }

    _capturing = true;
    _goodFrames = 0;

    try {
      if (camera.value.isStreamingImages) {
        await camera.stopImageStream();
      }

      final photo = await camera.takePicture();
      final file = File(photo.path);

      final qualityPassed = await _checkCapturedPhoto(file);
      if (!mounted) return;

      if (!qualityPassed) {
        setState(() {
          _status = 'Selfie is not clear';
          _qualityStatus =
              'Improve lighting, hold still and take the selfie again.';
        });
        await _restartImageStream();
        return;
      }

      setState(() {
        _selfieFile = file;
        _status = 'Selfie captured';
        _qualityStatus = 'Review your photo before continuing.';
      });
    } catch (_) {
      if (mounted) {
        _showMessage('Could not capture selfie. Please try again.');
      }
      await _restartImageStream();
    } finally {
      _capturing = false;
    }
  }

  Future<bool> _checkCapturedPhoto(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return false;

      if (decoded.width < 480 || decoded.height < 480) return false;

      // Basic brightness check; this is not a full image-quality guarantee.
      final sampleX = math.max(1, decoded.width ~/ 30);
      final sampleY = math.max(1, decoded.height ~/ 30);

      double totalBrightness = 0;
      int count = 0;

      for (int y = 0; y < decoded.height; y += sampleY) {
        for (int x = 0; x < decoded.width; x += sampleX) {
          final pixel = decoded.getPixel(x, y);
          totalBrightness +=
              (pixel.r.toDouble() + pixel.g.toDouble() + pixel.b.toDouble()) /
                  3;
          count++;
        }
      }

      if (count == 0) return false;
      final brightness = totalBrightness / count;
      return brightness >= 35 && brightness <= 235;
    } catch (_) {
      return false;
    }
  }

  Future<void> _restartImageStream() async {
    final camera = _camera;
    if (!mounted ||
        camera == null ||
        !camera.value.isInitialized ||
        camera.value.isStreamingImages ||
        _selfieFile != null) {
      return;
    }

    try {
      await camera.startImageStream(_processCameraFrame);
    } catch (_) {
      _updateStatus(
        'Camera needs restarting',
        'Tap Retry Camera to continue.',
      );
    }
  }

  Future<void> _retakeSelfie() async {
    if (_uploading || _capturing) return;

    setState(() {
      _selfieFile = null;
      _goodFrames = 0;
      _status = 'Position your face inside the frame';
      _qualityStatus = 'Waiting for your face';
    });

    await _restartImageStream();
  }

  Future<void> _confirmSelfie() async {
    final file = _selfieFile;
    if (file == null || _uploading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Your session expired. Please log in again.');
      return;
    }

    setState(() => _uploading = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath =
          'walker_selfies/${user.uid}/selfie_$timestamp.jpg';

      await FirebaseStorage.instance.ref(storagePath).putFile(
            file,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'userId': user.uid,
                'documentType': 'selfie',
              },
            ),
          );

      // Do not write walkerId from the client.
      await FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid)
          .set(
        {
          'userId': user.uid,
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

      await _stopCamera();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const KycDocumentsScreen(),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showMessage(
        e.code == 'permission-denied' || e.code == 'unauthorized'
            ? 'Access denied. Check Firebase Storage and Firestore rules.'
            : e.message ?? 'Unable to upload your selfie.',
      );
    } catch (_) {
      if (mounted) {
        _showMessage('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _stopCamera() async {
    final camera = _camera;
    _camera = null;
    _cameraReady = false;

    if (camera != null) {
      try {
        if (camera.value.isStreamingImages) {
          await camera.stopImageStream();
        }
      } catch (_) {}
      try {
        await camera.dispose();
      } catch (_) {}
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stopCamera());
    unawaited(_faceDetector?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewFile = _selfieFile;

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
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    children: [
                      const Center(
                        child: Text(
                          'DOJO PARTNER',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            color: DojoPartnerTheme.primaryOrange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Verify Your Identity',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: DojoPartnerTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        previewFile == null
                            ? 'Remove sunglasses or anything covering your face.'
                            : 'Check your selfie before continuing.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: DojoPartnerTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 370,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: DojoPartnerTheme.primaryOrange,
                            width: 2,
                          ),
                        ),
                        child: previewFile != null
                            ? Image.file(
                                previewFile,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 56,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : _buildCameraPreview(),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE7E7E7),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _status,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: DojoPartnerTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _qualityStatus,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: DojoPartnerTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFE8E8E8)),
                    ),
                  ),
                  child: previewFile == null
                      ? SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _initializing || _capturing || _uploading
                                ? null
                                : _initializeCamera,
                            child: Text(
                              _initializing
                                  ? 'Starting Camera...'
                                  : _cameraReady
                                      ? 'Automatic Capture Enabled'
                                      : 'Retry Camera',
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _uploading ? null : _retakeSelfie,
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
                                child: const Text('Retake Selfie'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _uploading ? null : _confirmSelfie,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      DojoPartnerTheme.primaryOrange,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                                child: _uploading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        'Continue',
                                        style: TextStyle(
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

  Widget _buildCameraPreview() {
    final camera = _camera;

    if (_initializing ||
        camera == null ||
        !camera.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: DojoPartnerTheme.primaryOrange,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        CameraPreview(camera),
        IgnorePointer(
          child: Center(
            child: Container(
              width: 240,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(120),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
