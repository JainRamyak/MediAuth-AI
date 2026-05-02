import 'package:flutter_test/flutter_test.dart';
import 'package:mediauth_flutter/auth/auth_service.dart';

void main() {
  group('AuthResult Tests', () {
    test('AuthResult.ok creates a success result', () {
      final result = AuthResult.ok(null);
      expect(result.success, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.user, isNull);
    });

    test('AuthResult.fail creates a failure result', () {
      final result = AuthResult.fail('Error message');
      expect(result.success, isFalse);
      expect(result.errorMessage, 'Error message');
      expect(result.user, isNull);
    });
  });
}
