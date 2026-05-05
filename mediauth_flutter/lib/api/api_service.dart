import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../screens/s06b_prompt_customization.dart';
import '../screens/s04_patient_info.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MediAuth AI — API Service
//
// All calls to the FastAPI backend go through this class.
// Base URL is read from .env (API_BASE_URL) with a platform-aware fallback.
//
// Authentication:
//   Every request includes an Authorization: Bearer <token> header, read securely
//   from FlutterSecureStorage.
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
  static const _storage = FlutterSecureStorage();

  // ── Base URL ────────────────────────────────────────────────────────────────

  static String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'https://rohitbhardwaj007-mediauth.hf.space/api/v1';
  }

  // ── Auth header ─────────────────────────────────────────────────────────────

  /// Returns headers with Content-Type and, if available, the Secure Storage JWT.
  static Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await _storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ── Health check ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> healthCheck() async {
    final url = Uri.parse('${baseUrl.replaceAll('/api/v1', '')}/health');
    try {
      final headers = await _headers();
      final res = await http
          .get(url, headers: headers)
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
      String patientText, String requestedTreatment, {PatientFormData? patient}) async {
    final url = Uri.parse('$baseUrl/authorize');
    try {
      final headers = await _headers();
      
      final Map<String, dynamic> body = {
        'patient_text': patientText,
        'requested_treatment': requestedTreatment,
      };

      if (patient != null) {
        final dob = patient.dateOfBirth;
        final dobStr = dob != null
            ? '${dob.year}-${dob.month.toString().padLeft(2,'0')}-${dob.day.toString().padLeft(2,'0')}'
            : null;
        body['structured_profile'] = {
          'name': patient.fullName,
          'date_of_birth': dobStr,
          'insurance_policy_number': patient.policyNumber,
          'insurer_name': patient.insurer,
          'diagnoses': patient.diagnoses,
          'medications': patient.medications,
          'allergies': patient.allergies,
          'medical_history': patient.medicalHistory,
        };
      }

      final res = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(body),
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

  // ── Appeal workflow ─────────────────────────────────────────────────────────

  /// POST /api/v1/authorize/{auth_request_id}/appeal
  /// Runs a dedicated manual appeal directly from Level 1 instead of from scratch.
  static Future<Map<String, dynamic>> submitAppeal(String authRequestId) async {
    final url = Uri.parse('$baseUrl/authorize/$authRequestId/appeal');
    try {
      final headers = await _headers();
      final res = await http
          .post(url, headers: headers)
          .timeout(const Duration(seconds: 120));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      
      String detail = 'Appeal failed';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        detail = body['detail']?.toString() ?? detail;
      } catch (_) {}
      throw ApiException(detail, statusCode: res.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error during appeal: $e');
    }
  }

  // ── Prompt management ───────────────────────────────────────────────────────

  /// GET /api/v1/prompts/
  /// Returns the list of all agent keys.
  static Future<List<String>> fetchPromptsList() async {
    final url = Uri.parse('$baseUrl/prompts/');
    try {
      final headers = await _headers();
      final res = await http
          .get(url, headers: headers)
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
      final headers = await _headers();
      final res = await http
          .get(url, headers: headers)
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
      final headers = await _headers();
      final res = await http
          .put(
            url,
            headers: headers,
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

  // ── History ─────────────────────────────────────────────────────────────────

  /// GET /api/v1/authorize?limit=50
  /// Returns the list of all past authorization requests from the database.
  static Future<List<Map<String, dynamic>>> fetchHistory({int limit = 50}) async {
    final url = Uri.parse('$baseUrl/authorize?limit=$limit');
    try {
      final headers = await _headers();
      final res = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw ApiException('Failed to load history', statusCode: res.statusCode);
      }
      final body = jsonDecode(res.body) as List<dynamic>;
      return body.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error loading history: $e');
    }
  }

  /// GET /api/v1/authorize/{auth_request_id}
  /// Returns a single authorization request by its UUID.
  static Future<Map<String, dynamic>> fetchAuthorizationById(String id) async {
    final url = Uri.parse('$baseUrl/authorize/$id');
    try {
      final headers = await _headers();
      final res = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 404) {
        throw ApiException('Authorization not found', statusCode: 404);
      }
      if (res.statusCode != 200) {
        throw ApiException('Failed to load authorization', statusCode: res.statusCode);
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error loading authorization: $e');
    }
  }
}

