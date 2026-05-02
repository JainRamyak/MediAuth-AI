import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock shared_preferences for all tests
  const MethodChannel('plugins.flutter.io/shared_preferences')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'getAll') {
      return <String, dynamic>{};
    }
    return null;
  });

  // Mock .env file loading
  dotenv.testLoad(fileInput: '''
    SUPABASE_URL=https://placeholder.supabase.co
    SUPABASE_ANON_KEY=placeholder
    GOOGLE_WEB_CLIENT_ID=placeholder
  ''');

  try {
    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      anonKey: 'placeholder',
    );
  } catch (e) {
    // Already initialized
  }

  await testMain();
}
