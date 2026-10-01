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

    test('TokenStorage saves and clears authentication session properly', () async {
      SharedPreferences.setMockInitialValues({});
      await TokenStorage.saveSession(
        token: 'test_real_jwt_token_2026',
        userId: 'u100',
        email: 'realuser@wearsy.app',
        fullName: 'Người Dùng Thật',
      );

      expect(await TokenStorage.hasToken(), isTrue);
      expect(await TokenStorage.getToken(), 'test_real_jwt_token_2026');
      expect(await TokenStorage.getUserEmail(), 'realuser@wearsy.app');
      expect(await TokenStorage.getUserName(), 'Người Dùng Thật');

      await TokenStorage.clearSession();
      expect(await TokenStorage.hasToken(), isFalse);
      expect(await TokenStorage.getToken(), isNull);
      expect(await TokenStorage.getUserEmail(), isNull);
    });

    test('upgradeVip with invalid coupon throws ApiException', () async {
      SharedPreferences.setMockInitialValues({});
      final authService = AuthService();

      expect(
        () => authService.upgradeVip(couponCode: 'INVALID_COUPON'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });
  });
}
