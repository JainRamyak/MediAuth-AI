import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediauth_flutter/screens/s02_login.dart';
import 'package:mediauth_flutter/screens/s02a_signup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock shared_preferences
    const MethodChannel('plugins.flutter.io/shared_preferences')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, dynamic>{}; // Return empty map for getAll
      }
      return null;
    });

    try {
      await Supabase.initialize(
        url: 'https://placeholder.supabase.co',
        anonKey: 'placeholder',
      );
    } catch (e) {
      // If already initialized
    }
  });

  group('Screen Tests', () {
    testWidgets('LoginScreen renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            onLogin: () {},
            onSignUp: () {},
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 500)); 

      expect(find.text('MediAuth AI'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('SignUpScreen renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SignUpScreen(
            onSignUpSuccess: () {},
            onSignIn: () {},
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsWidgets);
      expect(find.text('PERSONAL INFORMATION'), findsOneWidget);
      expect(find.text('HEALTH COVERAGE'), findsOneWidget);
      expect(find.text('ACCOUNT CREDENTIALS'), findsOneWidget);
    });
  });
}
