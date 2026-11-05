import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_partner/features/onboarding/screens/live_selfie_screen.dart';

void main() {
  group('liveSelfiePreviewHeight', () {
    test('uses the minimum preview height on compact screens', () {
      expect(liveSelfiePreviewHeight(480), 220);
    });

    test('scales preview height for standard screens', () {
      expect(liveSelfiePreviewHeight(800), closeTo(336, 0.001));
    });

    test('caps preview height on tall screens', () {
      expect(liveSelfiePreviewHeight(1200), 370);
    });

    test('keeps a usable preview in short landscape layouts', () {
      expect(liveSelfiePreviewHeight(360), 220);
    });
  });
}
