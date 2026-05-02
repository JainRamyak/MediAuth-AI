/// ---------------------------------------------------------------------------
/// auth_service.dart
/// ---------------------------------------------------------------------------

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
      // ✅ signInWithPassword — not signUp
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

      // ✅ email confirmation is OFF so user returned immediately
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

  // ── Google Sign-In ──────────────────────────────────────────────────────

  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn(
        clientId: kGoogleWebClientId,
      ).signIn();

      if (googleUser == null) {
        return AuthResult.fail('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        return AuthResult.fail('Could not retrieve Google ID token.');
      }

      final res = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      return AuthResult.ok(res.user);
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.fail('Google sign-in failed. Please try again.');
    }
  }

  // ── Password Reset ──────────────────────────────────────────────────────

  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: kSupabaseRedirectUrl,
      ).timeout(const Duration(seconds: 15));
      return AuthResult.ok(null);
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e.message));
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return AuthResult.fail('Connection timed out. Please check your internet or try again.');
      }
      return AuthResult.fail('Could not send reset email. Please try again.');
    }
  }

  // ── Sign Out ────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut().catchError((_) {});
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