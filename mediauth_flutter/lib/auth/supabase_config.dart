/// ---------------------------------------------------------------------------
/// supabase_config.dart
/// ---------------------------------------------------------------------------
/// Configuration for Supabase and Google OAuth.
/// Values are loaded from the .env file at runtime.
/// ---------------------------------------------------------------------------

library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase Project URL
String kSupabaseUrl = dotenv.env['SUPABASE_URL'] ?? 
    (throw Exception('SUPABASE_URL not set in .env'));

/// Supabase Anon/Public Key
String kSupabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 
    (throw Exception('SUPABASE_ANON_KEY not set in .env'));

/// Google OAuth Web Client ID (from Google Cloud Console).
/// Required for Google Sign-In to exchange tokens with Supabase.
String kGoogleWebClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? 
    'YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com';

/// Custom Redirect URL for OAuth flows
String kSupabaseRedirectUrl = dotenv.env['SUPABASE_REDIRECT_URL']?.trim() ?? 
    'com.mediauth.app://login-callback';
