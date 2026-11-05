import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Decodes the supplied image bytes and applies the existing selfie quality
/// contract. Invalid or undecodable image data is rejected.
bool isSelfiePhotoBytesAcceptable(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return false;
  return isSelfiePhotoImageAcceptable(decoded);
}

/// Applies the existing minimum-dimension and sampled-brightness checks.
///
/// This intentionally does not add blur, identity, or face-quality checks.
bool isSelfiePhotoImageAcceptable(img.Image decoded) {
  if (decoded.width < 480 || decoded.height < 480) {
    return false;
  }

  // Keep the original 30-step sampling behavior unchanged.
  final sampleX = decoded.width ~/ 30 < 1 ? 1 : decoded.width ~/ 30;
  final sampleY = decoded.height ~/ 30 < 1 ? 1 : decoded.height ~/ 30;

  double totalBrightness = 0;
  int count = 0;

  for (int y = 0; y < decoded.height; y += sampleY) {
    for (int x = 0; x < decoded.width; x += sampleX) {
      final pixel = decoded.getPixel(x, y);
      totalBrightness +=
          (pixel.r.toDouble() + pixel.g.toDouble() + pixel.b.toDouble()) / 3;
      count++;
    }
  }

  if (count == 0) return false;

  final brightness = totalBrightness / count;
  return brightness >= 35 && brightness <= 235;
}
