/// ---------------------------------------------------------------------------
/// auth_service.dart  — Custom FastAPI Authentication
/// ---------------------------------------------------------------------------
library;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_service.dart';

// ── Models ──────────────────────────────────────────────────────────────────

class User {
  final String id;
  final String email;
  final String? fullName;

  const User({required this.id, required this.email, this.fullName});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['name']?.toString(),
    );
  }
}

enum AuthChangeEvent { initialSession, signedIn, signedOut }

class AuthState {
  final AuthChangeEvent event;
  final User? user;
  const AuthState(this.event, this.user);
}

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
  
  static const _storage = FlutterSecureStorage();
  
  final _authStateController = StreamController<AuthState>.broadcast();
  User? _currentUser;

  // ── Current session / user ──────────────────────────────────────────────

  User? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Stream<AuthState> get onAuthStateChange => _authStateController.stream;

  // ── Initialization (called once in main.dart) ───────────────────────────
  
  Future<void> initialize() async {
    final token = await _storage.read(key: 'access_token');
    final userId = await _storage.read(key: 'user_id');
    final email = await _storage.read(key: 'email');
    final fullName = await _storage.read(key: 'full_name');
    
    if (token != null && userId != null && email != null) {
      _currentUser = User(id: userId, email: email, fullName: fullName);
      _authStateController.add(AuthState(AuthChangeEvent.initialSession, _currentUser));
    } else {
      _authStateController.add(AuthState(AuthChangeEvent.initialSession, null));
    }
  }

  // ── Email + Password Login ──────────────────────────────────────────────

  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/auth/login');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        
        await _storage.write(key: 'access_token', value: body['access_token']);
        await _storage.write(key: 'user_id', value: body['user_id']);
        await _storage.write(key: 'email', value: body['email']);
        await _storage.write(key: 'full_name', value: body['full_name']);
        
        _currentUser = User.fromJson(body);
        _authStateController.add(AuthState(AuthChangeEvent.signedIn, _currentUser));
        
        return AuthResult.ok(_currentUser);
      } else if (res.statusCode == 404) {
        return AuthResult.fail('This email is not registered.');
      } else if (res.statusCode == 401) {
        return AuthResult.fail('Incorrect password. Please try again.');
      } else {
        return AuthResult.fail('Login failed (${res.statusCode})');
      }
    } catch (e) {
      return AuthResult.fail('Network error during login.');
    }
  }

  // ── Email + Password Sign-Up ────────────────────────────────────────────

  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/auth/register');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'full_name': fullName.trim()
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        
        await _storage.write(key: 'access_token', value: body['access_token']);
        await _storage.write(key: 'user_id', value: body['user_id']);
        await _storage.write(key: 'email', value: body['email']);
        await _storage.write(key: 'full_name', value: body['full_name']);
        
        _currentUser = User.fromJson(body);
        _authStateController.add(AuthState(AuthChangeEvent.signedIn, _currentUser));
        
        return AuthResult.ok(_currentUser);
      } else if (res.statusCode == 400) {
        return AuthResult.fail('Email already registered.');
      } else {
        return AuthResult.fail('Sign up failed (${res.statusCode})');
      }
    } catch (e) {
      return AuthResult.fail('Network error during sign up.');
    }
  }

  // ── Sign Out ────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _storage.deleteAll();
    _currentUser = null;
    _authStateController.add(const AuthState(AuthChangeEvent.signedOut, null));
  }
}