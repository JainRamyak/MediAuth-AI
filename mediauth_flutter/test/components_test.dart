import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediauth_flutter/widgets/shared_widgets.dart';

void main() {
  group('Shared Widgets Tests', () {
    testWidgets('StatusPill displays correct label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusPill(AuthStatus.approved),
          ),
        ),
      );

      expect(find.text('Approved'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('StepHeader displays correct step information', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StepHeader(
              current: 1,
              total: 3,
              title: 'Test Title',
            ),
          ),
        ),
      );

      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('PrimaryButton displays label and handles taps', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Click Me',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
      await tester.tap(find.text('Click Me'));
      expect(tapped, isTrue);
    });

    testWidgets('SectionLabel displays title and icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionLabel('Section Title', Icons.person),
          ),
        ),
      );

      expect(find.text('SECTION TITLE'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}
