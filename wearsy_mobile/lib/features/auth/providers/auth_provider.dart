import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/email_service.dart';
import '../../../core/storage/token_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final hasToken = await TokenStorage.hasToken();
      if (hasToken) {
        _user = await _authService.getProfile();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      // Token might be expired or invalid
      await TokenStorage.clearSession();
      _user = null;
      _status = AuthStatus.unauthenticated;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final authData =
          await _authService.login(email: email, password: password);
      _user = authData.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final authData = await _authService.loginWithGoogle();
      _user = authData.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Đăng nhập Google thất bại. Vui lòng thử lại.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithFacebook() async {
    _setLoading(true);
    _clearError();

    try {
      final authData = await _authService.loginWithFacebook();
      _user = authData.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Đăng nhập Facebook thất bại. Vui lòng thử lại.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(
    String fullName,
    String email,
    String password, {
    String? gender,
    DateTime? birthDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final authData = await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
        gender: gender,
        birthDate: birthDate,
      );
      _user = authData.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Đăng ký thất bại. Email có thể đã được sử dụng.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<EmailSendResult> sendOtpEmail(String email, {String? fullName}) async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _authService.sendOtpEmail(email, fullName: fullName);
      if (!result.success && result.errorMessage != null) {
        _setError(result.errorMessage!);
      }
      return result;
    } catch (e) {
      final err = 'Không thể gửi mã OTP về email: ${e.toString()}';
      _setError(err);
      return EmailSendResult(success: false, errorMessage: err);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOtp(String email, String otpCode) async {
    return await _authService.verifyOtp(email, otpCode);
  }

  Future<bool> updateStyleProfile(Map<String, dynamic> styleData) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await _authService.updateStyleProfile(styleData);
      _user = updatedUser;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Cập nhật hồ sơ phong cách thất bại.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserInfo({required String fullName}) async {
    _setLoading(true);
    _clearError();
    try {
      if (_user != null) {
        _user = _user!.copyWith(fullName: fullName);
        final token = await TokenStorage.getToken() ?? 'mock_token';
        await TokenStorage.saveSession(
          token: token,
          userId: _user!.id,
          email: _user!.email,
          fullName: fullName,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Cập nhật thông tin thất bại.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Đổi mật khẩu thất bại. Vui lòng thử lại.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.deleteAccount();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Xóa tài khoản thất bại. Vui lòng thử lại.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> upgradeVip(String couponCode) async {
    _setLoading(true);
    _clearError();
    try {
      final updatedUser = await _authService.upgradeVip(couponCode: couponCode);
      _user = updatedUser;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Nâng cấp VIP thất bại. Vui lòng kiểm tra lại mã coupon.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetAccountsToDefault() async {
    await _authService.resetAllAccountsToDefault();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
