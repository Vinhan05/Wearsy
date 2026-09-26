import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearsy_mobile/core/network/api_client.dart';
import 'package:wearsy_mobile/core/storage/token_storage.dart';
import 'package:wearsy_mobile/features/auth/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Validation & Security Tests', () {
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)');

    test('Password complexity regex requires letters and numbers', () {
      expect(passwordRegex.hasMatch('123456'), isFalse);
      expect(passwordRegex.hasMatch('password'), isFalse);
      expect(passwordRegex.hasMatch('pass123'), isTrue);
      expect(passwordRegex.hasMatch('Wearsy2026'), isTrue);
    });

    test('Password length validation enforces minimum 6 characters', () {
      bool isValidLength(String pass) => pass.length >= 6;
      expect(isValidLength('12345'), isFalse);
      expect(isValidLength('123456'), isTrue);
      expect(isValidLength('wearsy123'), isTrue);
    });

    test('Email format validation checks @ and domain', () {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      expect(emailRegex.hasMatch('invalidemail'), isFalse);
      expect(emailRegex.hasMatch('user@'), isFalse);
      expect(emailRegex.hasMatch('vothimydung.fpt@gmail.com'), isTrue);
      expect(emailRegex.hasMatch('customer@wearsy.app'), isTrue);
    });

    test('Demo account logs in successfully with correct password 123456', () async {
      SharedPreferences.setMockInitialValues({});
      final authService = AuthService();
      final result = await authService.login(
        email: 'demo@wearsy.app',
        password: '123456',
      );
      expect(result.user.email, 'demo@wearsy.app');
      expect(result.token, isNotEmpty);
    });

    test('Demo account throws 401 ApiException when password is wrong', () async {
      SharedPreferences.setMockInitialValues({});
      final authService = AuthService();

      expect(
        () => authService.login(
          email: 'demo@wearsy.app',
          password: 'wrong_password',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', contains('Email hoặc mật khẩu không chính xác')),
        ),
      );
    });

    test('Test account throws 401 ApiException when password is wrong', () async {
      SharedPreferences.setMockInitialValues({});
      final authService = AuthService();

      expect(
        () => authService.login(
          email: 'test@wearsy.app',
          password: 'ffffffff',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', contains('Email hoặc mật khẩu không chính xác')),
        ),
      );
    });

    test('Unregistered account throws ApiException when login fails', () async {
      SharedPreferences.setMockInitialValues({});
      final authService = AuthService();

      expect(
        () => authService.login(
          email: 'unknown_user@random.com',
          password: 'randompassword123',
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('Style profile updates and persists properly in local storage', () async {
      SharedPreferences.setMockInitialValues({});
      final authService = AuthService();
      await authService.login(
        email: 'demo@wearsy.app',
        password: '123456',
      );

      final updated = await authService.updateStyleProfile({
        'preferred_styles': ['Thanh lịch', 'Năng động', 'Công sở'],
        'color_preferences': {
          'favorites': ['Trắng', 'Đen', 'Xanh Navy', 'Beige', 'Xám'],
          'avoid': [],
        },
        'budget_range': {
          'min': 300000.0,
          'max': 3200000.0,
        },
        'body_measurements': {
          'height': 175,
          'weight': 68,
          'body_shape': 'Tam giác ngược (Inverted Triangle)',
        },
      });

      expect(updated.preferredStyles, containsAll(['Thanh lịch', 'Năng động', 'Công sở']));
      expect(updated.colorPreferences?['favorites'], containsAll(['Trắng', 'Đen', 'Xanh Navy']));
      expect(updated.budgetRange?['max'], 3200000.0);
      expect(updated.bodyMeasurements?['height'], 175);

      // Verify getProfile returns the updated saved profile
      final retrieved = await authService.getProfile();
      expect(retrieved.preferredStyles, containsAll(['Thanh lịch', 'Năng động', 'Công sở']));
      expect(retrieved.colorPreferences?['favorites'], containsAll(['Trắng', 'Đen', 'Xanh Navy']));
      expect(retrieved.budgetRange?['max'], 3200000.0);
      expect(retrieved.bodyMeasurements?['height'], 175);
    });

    test('Change password flow works correctly and updates login credentials', () async {
      SharedPreferences.setMockInitialValues({});
      final authService = AuthService();

      // Login initially with demo default password '123456'
      await authService.login(
        email: 'demo@wearsy.app',
        password: '123456',
      );

      // Attempting to change password with WRONG old password should fail
      expect(
        () => authService.changePassword(
          oldPassword: 'wrongoldpass',
          newPassword: 'newPassword123',
        ),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('Mật khẩu hiện tại không chính xác'))),
      );

      // Changing password with CORRECT old password succeeds
      await authService.changePassword(
        oldPassword: '123456',
        newPassword: 'newPassword123',
      );

      // Now logging in with OLD password '123456' should FAIL
      expect(
        () => authService.login(
          email: 'demo@wearsy.app',
          password: '123456',
        ),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      // Logging in with NEW password 'newPassword123' must SUCCEED
      final loginResult = await authService.login(
        email: 'demo@wearsy.app',
        password: 'newPassword123',
      );
      expect(loginResult.user.email, 'demo@wearsy.app');
      expect(loginResult.token, isNotEmpty);
    });

    test('deleteAccount removes all user credentials and session data', () async {
      SharedPreferences.setMockInitialValues({});
      final authService = AuthService();

      await authService.login(
        email: 'demo@wearsy.app',
        password: '123456',
      );

      // Verify session exists
      expect(await TokenStorage.hasToken(), isTrue);

      // Execute deleteAccount
      await authService.deleteAccount();

      // Verify token cleared
      expect(await TokenStorage.hasToken(), isFalse);
      expect(await TokenStorage.getUserEmail(), isNull);
    });
  });
}
