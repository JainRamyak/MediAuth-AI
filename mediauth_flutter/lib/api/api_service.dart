import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;
import '../screens/s06b_prompt_customization.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MediAuth AI — API Service
//
// All calls to the FastAPI backend go through this class.
// Base URL is read from .env (API_BASE_URL) with a platform-aware fallback.
//
// Authentication:
//   Every request includes an Authorization: Bearer <supabase_jwt> header.
//   The current backend does not validate tokens, but the header is included
//   for forward-compatibility when auth middleware is added.
// ─────────────────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => statusCode != null
      ? 'ApiException($statusCode): $message'
      : 'ApiException: $message';
}

class ApiService {
  // ── Base URL ────────────────────────────────────────────────────────────────

  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;

    // Platform-aware fallback — keeps dev working even without .env
    bool isAndroid;
    try {
      isAndroid = Platform.isAndroid;
    } catch (_) {
      isAndroid = false; // Web / Desktop
    }
    return isAndroid
        ? 'http://10.0.2.2:8000/api/v1'
        : 'http://127.0.0.1:8000/api/v1';
  }

  // ── Auth header ─────────────────────────────────────────────────────────────

  /// Returns headers with Content-Type and, if available, the Supabase JWT.
  static Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      headers['Authorization'] = 'Bearer ${session.accessToken}';
    }

    return headers;
  }

  // ── Health check ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> healthCheck() async {
    final url = Uri.parse('${baseUrl.replaceAll('/api/v1', '')}/health');
    try {
      final res = await http
          .get(url, headers: _headers())
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw ApiException('Health check failed', statusCode: res.statusCode);
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Cannot reach backend: $e');
    }
  }

  // ── Authorization workflow ──────────────────────────────────────────────────

  /// POST /api/v1/authorize
  /// Runs the full 7-agent pipeline.
  /// Timeout: 120 seconds — real AI pipeline can take 45–90s.
  static Future<Map<String, dynamic>> authorizeTreatment(
      String patientText, String requestedTreatment) async {
    final url = Uri.parse('$baseUrl/authorize');
    try {
      final res = await http
          .post(
            url,
            headers: _headers(),
            body: jsonEncode({
              'patient_text': patientText,
              'requested_treatment': requestedTreatment,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }

      // Try to extract a meaningful error message from FastAPI's detail field
      String detail = 'Authorization pipeline failed';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        detail = body['detail']?.toString() ?? detail;
      } catch (_) {}
      throw ApiException(detail, statusCode: res.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error during authorization: $e');
    }
  }

  // ── Prompt management ───────────────────────────────────────────────────────

  /// GET /api/v1/prompts/
  /// Returns the list of all agent keys.
  static Future<List<String>> fetchPromptsList() async {
    final url = Uri.parse('$baseUrl/prompts/');
    try {
      final res = await http
          .get(url, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw ApiException('Failed to list prompts', statusCode: res.statusCode);
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return List<String>.from(body['agents'] as List);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error fetching prompts list: $e');
    }
  }

  /// GET /api/v1/prompts/{agent}
  /// Returns {system, user_template} for the given agent key.
  static Future<Map<String, String>> fetchPrompt(String agentKey) async {
    final url = Uri.parse('$baseUrl/prompts/$agentKey');
    try {
      final res = await http
          .get(url, headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 404) {
        throw ApiException("Agent '$agentKey' not found", statusCode: 404);
      }
      if (res.statusCode != 200) {
        throw ApiException('Failed to fetch prompt for $agentKey',
            statusCode: res.statusCode);
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return {
        'system': body['system']?.toString() ?? '',
        'user_template': body['user_template']?.toString() ?? '',
      };
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error fetching prompt for $agentKey: $e');
    }
  }

  /// PUT /api/v1/prompts/{agent}
  /// Updates the system prompt and user template for an agent.
  /// Used by both s06b (pre-submit customization) and s13 (prompt editor).
  static Future<void> updatePromptDirect(
      String agentKey, String system, String userTemplate) async {
    final url = Uri.parse('$baseUrl/prompts/$agentKey');
    try {
      final res = await http
          .put(
            url,
            headers: _headers(),
            body: jsonEncode({
              'system': system,
              'user_template': userTemplate,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        String detail = 'Failed to update prompt for $agentKey';
        try {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          detail = body['detail']?.toString() ?? detail;
        } catch (_) {}
        throw ApiException(detail, statusCode: res.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error updating prompt for $agentKey: $e');
    }
  }

  /// PUT /api/v1/prompts/{agent}
  /// Convenience overload used by s06b PromptCustomizationScreen.
  /// Accepts an [AgentPromptData] object (same signature as before).
  static Future<void> updatePrompt(AgentPromptData agent) =>
      updatePromptDirect(agent.key, agent.systemPrompt, agent.userTemplate);
}
