import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> enterManualReportAddress(
  WidgetTester tester,
  String street,
) async {
  await tester.ensureVisible(find.text('Centro, Cuautla').first);
  await tester.tap(find.text('Centro, Cuautla').first);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('manual-address-0')),
    street,
  );
  await tester.enterText(
    find.byKey(const ValueKey('manual-address-2')),
    'Centro',
  );
  await tester.enterText(
    find.byKey(const ValueKey('manual-address-3')),
    '62740',
  );
  await tester.ensureVisible(find.text('Usar dirección'));
  await tester.tap(find.text('Usar dirección'));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}
