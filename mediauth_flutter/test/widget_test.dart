import 'package:flutter_test/flutter_test.dart';
import 'package:mediauth_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MediAuthApp());
    expect(find.byType(MediAuthApp), findsOneWidget);
  });
}
