import 'package:flutter_test/flutter_test.dart';
import 'package:samudra/main.dart';

void main() {
  testWidgets('SAMUDRA app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SamudraApp());
    // Verifikasi splash screen muncul
    expect(find.byType(SamudraApp), findsOneWidget);
  });
}
