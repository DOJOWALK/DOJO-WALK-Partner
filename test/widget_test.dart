import 'package:flutter_test/flutter_test.dart';

import 'package:dojo_partner/app.dart';

void main() {
  testWidgets('DOJO Partner app builds successfully', (tester) async {
    await tester.pumpWidget(const DojoPartnerApp());

    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
  });
}
