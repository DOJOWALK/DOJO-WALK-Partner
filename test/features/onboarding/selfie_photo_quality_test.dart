import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:dojo_partner/features/onboarding/utils/selfie_photo_quality.dart';

void main() {
  group('isSelfiePhotoBytesAcceptable', () {
    test('rejects undecodable bytes', () {
      expect(isSelfiePhotoBytesAcceptable(Uint8List.fromList(<int>[1, 2, 3])), isFalse);
    });
  });

  group('isSelfiePhotoImageAcceptable', () {
    img.Image solidImage(int width, int height, int brightness) {
      return img.Image(width: width, height: height)
        ..clear(color: img.ColorRgb8(brightness, brightness, brightness));
    }

    test('rejects images smaller than 480 pixels in either dimension', () {
      expect(isSelfiePhotoImageAcceptable(solidImage(479, 480, 120)), isFalse);
      expect(isSelfiePhotoImageAcceptable(solidImage(480, 479, 120)), isFalse);
    });

    test('accepts the inclusive lower brightness boundary of 35', () {
      expect(isSelfiePhotoImageAcceptable(solidImage(480, 480, 35)), isTrue);
    });

    test('accepts the inclusive upper brightness boundary of 235', () {
      expect(isSelfiePhotoImageAcceptable(solidImage(480, 480, 235)), isTrue);
    });

    test('rejects brightness below 35', () {
      expect(isSelfiePhotoImageAcceptable(solidImage(480, 480, 34)), isFalse);
    });

    test('rejects brightness above 235', () {
      expect(isSelfiePhotoImageAcceptable(solidImage(480, 480, 236)), isFalse);
    });

    test('accepts a valid image within the existing quality bounds', () {
      expect(isSelfiePhotoImageAcceptable(solidImage(640, 640, 120)), isTrue);
    });
  });
}
