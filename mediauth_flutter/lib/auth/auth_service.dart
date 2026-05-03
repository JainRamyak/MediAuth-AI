/// ---------------------------------------------------------------------------
/// auth_service.dart  — uses Supabase OAuth browser flow for Google Sign-In
/// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

// ── Result wrapper ──────────────────────────────────────────────────────────

class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;

  const AuthResult._({
    required this.success,
    this.errorMessage,
    this.user,
  });

  factory AuthResult.ok(User? user) =>
      AuthResult._(success: true, user: user);

  factory AuthResult.fail(String message) =>
      AuthResult._(success: false, errorMessage: message);
}

// ── AuthService ─────────────────────────────────────────────────────────────

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  // ── Current session / user ──────────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isSignedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Email + Password Login ──────────────────────────────────────────────

  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Verify if the email is present in the database before logging in.
      // If the user hasn't deployed the SQL RPC, this catch block falls back to default logic.
      try {
        final emailExists = await _client.rpc('check_email_exists', params: {'lookup_email': email.trim()});
        if (emailExists == false) {
          return AuthResult.fail('EMAIL_NOT_FOUND');
        }
      } catch (_) {
        // Fallback: RPC not created yet, just attempt login natively
      }

      final res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.ok(res.user);
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.fail('Unexpected error. Please try again.');
    }
  }

  // ── Email + Password Sign-Up ────────────────────────────────────────────

  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: metadata,
      );

      if (res.user != null) {
        return AuthResult.ok(res.user);
      }

      return AuthResult.fail('Sign up failed. Please try again.');
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.fail('Unexpected error. Please try again.');
    }
  }

  // ── Google Sign-In (browser OAuth flow) ────────────────────────────────
  // Opens a browser/Chrome Custom Tab for Google sign-in.
  // Supabase handles the token exchange and calls back via the deep link.

  Future<AuthResult> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : kSupabaseRedirectUrl,
      );
      // signInWithOAuth launches the browser and returns immediately.
      // The actual sign-in result arrives via the onAuthStateChange stream
      // in main.dart. Return a success-pending sentinel to unblock the UI.
      return AuthResult.ok(null);
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.fail('Google sign-in failed. Please try again.');
    }
  }

  // ── Update Metadata ───────────────────────────────────────────────────────
  
  Future<AuthResult> updateUserMetadata(Map<String, dynamic> metadata) async {
    try {
      final res = await _client.auth.updateUser(
        UserAttributes(data: metadata),
      );
      if (res.user != null) {
        return AuthResult.ok(res.user);
      }
      return AuthResult.fail('Could not update profile information.');
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.fail('Unexpected error. Please try again.');
    }
  }

  // ── Password Reset ──────────────────────────────────────────────────────

  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: kIsWeb ? null : kSupabaseRedirectUrl,
      );
      return AuthResult.ok(null);
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.fail('Could not send reset email. Please try again.');
    }
  }

  // ── Sign Out ────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _mapAuthError(String raw) {
    final msg = raw.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid email or password')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email address before signing in.';
    }
    if (msg.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('password should be')) {
      return 'Password must be at least 6 characters.';
    }
    return raw;
  }
}