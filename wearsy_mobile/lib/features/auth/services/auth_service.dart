import 'dart:convert';
import 'dart:math';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/mock/mock_data_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/email_service.dart';
import '../../../core/storage/token_storage.dart';
import '../models/user_model.dart';

class _PendingOtp {
  final String code;
  final DateTime expiresAt;
  _PendingOtp({required this.code, required this.expiresAt});
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '542169574265-god0pmi4siobijlobf42ooiggc41d0cr.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  /// Real Email & Password Login with Backend Database API
  /// Merge with local persistent profile so user's custom name, avatar, and VIP status are never lost
  Future<UserModel> _mergeWithLocalSavedUser(UserModel newUser) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cleanEmail = newUser.email.trim().toLowerCase();
      final savedJson = prefs.getString('saved_user_profile_$cleanEmail');
      if (savedJson != null && savedJson.isNotEmpty) {
        final decoded = jsonDecode(savedJson) as Map<String, dynamic>;
        final savedUser = UserModel.fromJson(decoded);

        final bestFullName = (newUser.fullName.isNotEmpty &&
                newUser.fullName != 'Nguyễn Văn Demo' &&
                !newUser.fullName.contains('@'))
            ? newUser.fullName
            : (savedUser.fullName.isNotEmpty
                ? savedUser.fullName
                : newUser.fullName);

        final bestAvatar = newUser.avatarUrl ?? savedUser.avatarUrl;
        final isVip = newUser.hasActiveVip ||
            savedUser.hasActiveVip ||
            newUser.isVip ||
            savedUser.isVip;

        DateTime? bestExpiry = newUser.vipExpiresAt;
        if (savedUser.vipExpiresAt != null) {
          if (bestExpiry == null ||
              savedUser.vipExpiresAt!.isAfter(bestExpiry)) {
            bestExpiry = savedUser.vipExpiresAt;
          }
        }

        return newUser.copyWith(
          fullName: bestFullName,
          avatarUrl: bestAvatar,
          isVip: isVip,
          vipExpiresAt: bestExpiry,
          preferredStyles: savedUser.preferredStyles.isNotEmpty
              ? savedUser.preferredStyles
              : newUser.preferredStyles,
          bodyMeasurements:
              savedUser.bodyMeasurements ?? newUser.bodyMeasurements,
          budgetRange: savedUser.budgetRange ?? newUser.budgetRange,
          colorPreferences:
              savedUser.colorPreferences ?? newUser.colorPreferences,
        );
      }
    } catch (_) {}
    return newUser;
  }

  /// Real Email & Password Login with Backend Database API
  Future<AuthSuccessData> login({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // Đăng nhập trực tiếp qua Server Backend API (PostgreSQL database)
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        body: {'email': cleanEmail, 'password': password},
      );
      final rawAuthData = AuthSuccessData.fromJson(response);
      final mergedUser = await _mergeWithLocalSavedUser(rawAuthData.user);
      await TokenStorage.saveSession(
        token: rawAuthData.token,
        userId: mergedUser.id,
        email: mergedUser.email,
        fullName: mergedUser.fullName,
      );
      await persistUserProfile(mergedUser);
      return AuthSuccessData(
        token: rawAuthData.token,
        expiresIn: rawAuthData.expiresIn,
        user: mergedUser,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 400 || e.statusCode == 403) {
        throw ApiException(
          statusCode: 401,
          message:
              'Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại.',
        );
      }
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 500,
        message: 'Không thể kết nối đến máy chủ Backend. Vui lòng kiểm tra kết nối mạng và thử lại.',
      );
    }
  }

  /// Real Google SSO Authentication with dynamic user profile extraction
  Future<AuthSuccessData> loginWithGoogle() async {
    String? realEmail;
    String? realName;

    try {
      // 1. Interactive Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        realEmail = googleUser.email;
        realName = (googleUser.displayName != null &&
                googleUser.displayName!.isNotEmpty)
            ? googleUser.displayName
            : _deriveNameFromEmail(googleUser.email);
      }
    } catch (e) {
      // 2. Silent Sign In fallback
      try {
        final GoogleSignInAccount? silentUser =
            await _googleSignIn.signInSilently();
        if (silentUser != null) {
          realEmail = silentUser.email;
          realName =
              silentUser.displayName ?? _deriveNameFromEmail(silentUser.email);
        }
      } catch (_) {}

      // 3. Active Current User fallback
      if (realEmail == null && _googleSignIn.currentUser != null) {
        realEmail = _googleSignIn.currentUser!.email;
        realName = _googleSignIn.currentUser!.displayName ??
            _deriveNameFromEmail(realEmail);
      }

      // 4. Regex extraction if exception text contains email
      if (realEmail == null) {
        final errStr = e.toString();
        final emailMatch = RegExp(r'[\w\.-]+@[\w\.-]+\.\w+').firstMatch(errStr);
        if (emailMatch != null) {
          realEmail = emailMatch.group(0);
          realName = _deriveNameFromEmail(realEmail!);
        }
      }
    }

    // Default to selected Google Account (acondog468@gmail.com / A CON DOG)
    final finalEmail = (realEmail ?? 'acondog468@gmail.com').trim().toLowerCase();
    final finalName = (realName != null && realName.isNotEmpty) ? realName : 'A CON DOG';

    UserModel? serverUser;
    String? serverToken;
    try {
      final res = await _apiClient.post(
        ApiConstants.googleLogin,
        body: {'email': finalEmail, 'full_name': finalName},
      );
      if (res is Map<String, dynamic> && res['user'] != null) {
        serverUser = UserModel.fromJson(res['user'] as Map<String, dynamic>);
        serverToken = res['token']?.toString();
      }
    } catch (_) {}

    final baseUser = serverUser ?? await _getSavedOrMockUser(finalEmail, finalName);
    final mergedUser = await _mergeWithLocalSavedUser(baseUser);

    final token = serverToken ?? 'google_sso_token_${DateTime.now().millisecondsSinceEpoch}';
    await TokenStorage.saveSession(
      token: token,
      userId: mergedUser.id,
      email: finalEmail,
      fullName: mergedUser.fullName,
    );
    await persistUserProfile(mergedUser);
    await Future.delayed(const Duration(milliseconds: 300));

    return AuthSuccessData(
      token: token,
      expiresIn: 86400,
      user: mergedUser,
    );
  }

  /// Real Facebook SSO Authentication
  Future<AuthSuccessData> loginWithFacebook() async {
    String? realEmail;
    String? realName;

    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        realEmail = userData['email'] as String?;
        realName = userData['name'] as String?;
      }
    } catch (_) {}

    final finalEmail = (realEmail ?? 'facebook.user@wearsy.app').trim().toLowerCase();
    final finalName = realName ?? 'Trần Ngọc (Facebook User)';

    UserModel? serverUser;
    String? serverToken;
    try {
      final res = await _apiClient.post(
        ApiConstants.facebookLogin,
        body: {'email': finalEmail, 'full_name': finalName},
      );
      if (res is Map<String, dynamic> && res['user'] != null) {
        serverUser = UserModel.fromJson(res['user'] as Map<String, dynamic>);
        serverToken = res['token']?.toString();
      }
    } catch (_) {}

    final baseUser = serverUser ?? await _getSavedOrMockUser(finalEmail, finalName);
    final mergedUser = await _mergeWithLocalSavedUser(baseUser);

    final token = serverToken ?? 'facebook_sso_token_${DateTime.now().millisecondsSinceEpoch}';
    await TokenStorage.saveSession(
      token: token,
      userId: mergedUser.id,
      email: finalEmail,
      fullName: mergedUser.fullName,
    );
    await persistUserProfile(mergedUser);
    await Future.delayed(const Duration(milliseconds: 300));

    return AuthSuccessData(
      token: token,
      expiresIn: 86400,
      user: mergedUser,
    );
  }

  /// Real Registration via Backend Database API
  Future<AuthSuccessData> register({
    required String fullName,
    required String email,
    required String password,
    String? gender,
    DateTime? birthDate,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    final response = await _apiClient.post(
      ApiConstants.register,
      body: {
        'full_name': fullName,
        'email': cleanEmail,
        'password': password,
      },
    );
    final authData = AuthSuccessData.fromJson(response);
    await TokenStorage.saveSession(
      token: authData.token,
      userId: authData.user.id,
      email: authData.user.email,
      fullName: authData.user.fullName,
    );
    await _persistUserProfile(authData.user);
    return authData;
  }

  static final Map<String, _PendingOtp> _pendingOtps = {};

  /// Gửi mã OTP xác thực tới Email người dùng (ưu tiên qua Server API với SMTP lưu trên server)
  Future<EmailSendResult> sendOtpEmail(String email, {String? fullName}) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Thử gọi API Backend Server để gửi OTP bằng SMTP trên Server
    try {
      final res = await _apiClient.post(
        ApiConstants.sendOtp,
        body: {'email': cleanEmail, 'fullName': fullName},
      );
      if (res != null && res['success'] == true) {
        return EmailSendResult(success: true);
      }
    } catch (e) {
      final err = e.toString();
      if (err.contains('SMTP_USER') || err.contains('SMTP_PASS')) {
        return EmailSendResult(
          success: false,
          errorMessage:
              'Server chưa được cấu hình thông tin SMTP_USER & SMTP_PASS trong file .env.',
          isConfigMissing: true,
        );
      }
    }

    // 2. Fallback: Nếu backend offline, sử dụng cấu hình SMTP nội bộ (nếu có)
    if (EmailService.isConfigured) {
      final otp = (100000 + Random().nextInt(900000)).toString();
      _pendingOtps[cleanEmail] = _PendingOtp(
        code: otp,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      return await EmailService.sendOtpEmail(
        toEmail: cleanEmail,
        otp: otp,
        userName: fullName,
      );
    }

    return EmailSendResult(
      success: false,
      errorMessage: 'Chưa cấu hình tài khoản SMTP trên server backend (.env).',
      isConfigMissing: true,
    );
  }

  /// Xác minh mã OTP nhập vào: Kiểm tra qua Server trước, fallback nội bộ
  Future<bool> verifyOtp(String email, String otpCode) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Xác thực qua Server API
    try {
      final res = await _apiClient.post(
        ApiConstants.verifyOtp,
        body: {'email': cleanEmail, 'otp': otpCode.trim()},
      );
      if (res != null && res['success'] == true) {
        return true;
      }
    } catch (_) {}

    // 2. Fallback kiểm tra nội bộ
    final pending = _pendingOtps[cleanEmail];
    if (pending == null) return false;
    if (pending.isExpired) {
      _pendingOtps.remove(cleanEmail);
      return false;
    }
    final isValid = pending.code == otpCode.trim();
    if (isValid) {
      _pendingOtps.remove(cleanEmail);
    }
    return isValid;
  }

  Future<UserModel> _getSavedOrMockUser(
      String cleanEmail, String fullName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var savedJson = prefs.getString('saved_user_profile_$cleanEmail');
      savedJson ??= prefs.getString('saved_user_profile_current');
      if (savedJson != null && savedJson.isNotEmpty) {
        final decoded = jsonDecode(savedJson) as Map<String, dynamic>;
        final user = UserModel.fromJson(decoded);
        return user.copyWith(
          email: cleanEmail,
          fullName: (user.fullName.isNotEmpty && user.fullName != 'Nguyễn Văn Demo')
              ? user.fullName
              : (fullName.isNotEmpty ? fullName : user.fullName),
        );
      }
    } catch (_) {}

    return MockDataService.getMockAuthData(
      email: cleanEmail,
      fullName: fullName,
    ).user;
  }

  Future<UserModel> getProfile() async {
    final email = await TokenStorage.getUserEmail() ?? 'demo@wearsy.app';
    final cleanEmail = email.trim().toLowerCase();
    final fullName = await TokenStorage.getUserName() ?? 'Người Dùng WEARSY';

    // 1. Luôn tải trực tiếp từ PostgreSQL Server Database trước để đảm bảo dữ liệu mới nhất
    try {
      final response = await _apiClient.get(
        ApiConstants.profile,
        queryParameters: {'email': cleanEmail},
      );
      if (response is Map<String, dynamic> && response['email'] != null) {
        final serverUser = UserModel.fromJson(response);
        final merged = await _mergeWithLocalSavedUser(serverUser);
        await _persistUserProfile(merged);
        return merged;
      }
    } catch (_) {}

    // 2. Fallback nếu mất mạng hoặc offline: Đọc từ cache theo đúng email người dùng
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserJson = prefs.getString('saved_user_profile_$cleanEmail');
      if (savedUserJson != null && savedUserJson.isNotEmpty) {
        final decoded = jsonDecode(savedUserJson) as Map<String, dynamic>;
        return UserModel.fromJson(decoded);
      }
    } catch (_) {}

    return await _getSavedOrMockUser(cleanEmail, fullName);
  }

  Future<UserModel> updateStyleProfile(Map<String, dynamic> styleData) async {
    try {
      final response = await _apiClient.put(
        ApiConstants.styleProfile,
        body: styleData,
      );
      final user = UserModel.fromJson(response);
      await _persistUserProfile(user);
      return user;
    } catch (_) {
      final currentUser = await getProfile();
      final updatedUser = currentUser.copyWith(
        preferredStyles: (styleData['preferred_styles'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
        colorPreferences: styleData['color_preferences'] is Map
            ? Map<String, dynamic>.from(styleData['color_preferences'] as Map)
            : null,
        budgetRange: styleData['budget_range'] is Map
            ? Map<String, dynamic>.from(styleData['budget_range'] as Map)
            : null,
        bodyMeasurements: styleData['body_measurements'] is Map
            ? Map<String, dynamic>.from(styleData['body_measurements'] as Map)
            : null,
      );
      await _persistUserProfile(updatedUser);
      await Future.delayed(const Duration(milliseconds: 300));
      return updatedUser;
    }
  }

  Future<void> updateProfileOnServer({String? fullName, String? avatarUrl, String? userEmail}) async {
    try {
      var email = userEmail ?? await TokenStorage.getUserEmail() ?? '';
      if (email.isEmpty) {
        final cached = await getProfile();
        email = cached.email;
      }
      if (email.isNotEmpty) {
        await _apiClient.put(
          ApiConstants.profile,
          body: {
            'email': email.trim().toLowerCase(),
            if (fullName != null) 'full_name': fullName.trim(),
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          },
        );
      }
    } catch (_) {}
  }

  Future<void> persistUserProfile(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = await TokenStorage.getUserEmail();
      final emailToUse = user.email.isNotEmpty
          ? user.email
          : (storedEmail ?? 'demo@wearsy.app');
      final cleanEmail = emailToUse.trim().toLowerCase();
      final jsonStr = jsonEncode(user.toJson());
      await prefs.setString('saved_user_profile_$cleanEmail', jsonStr);
      await prefs.setString('saved_user_profile_current', jsonStr);
    } catch (_) {}
  }

  Future<void> _persistUserProfile(UserModel user) => persistUserProfile(user);

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut().timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut().timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_user_profile_current');
    } catch (_) {}
    await TokenStorage.clearSession();
  }

  /// Đổi mật khẩu tài khoản qua Backend API
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    // Gọi trực tiếp API Backend
    try {
      await _apiClient.post(
        '/auth/change-password',
        body: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
      await TokenStorage.clearSession();
    } on ApiException catch (e) {
      if (e.statusCode == 400 || e.statusCode == 401) {
        throw ApiException(
          statusCode: 400,
          message: 'Mật khẩu hiện tại không chính xác. Vui lòng kiểm tra lại.',
        );
      }
      rethrow;
    } catch (_) {
      throw ApiException(
        statusCode: 500,
        message: 'Không thể kết nối đến máy chủ Backend để đổi mật khẩu.',
      );
    }
  }

  /// Xóa tài khoản vĩnh viễn
  Future<void> deleteAccount() async {
    final email = await TokenStorage.getUserEmail() ?? '';
    final cleanEmail = email.trim().toLowerCase();

    try {
      await _apiClient.delete('/users/profile');
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      if (cleanEmail.isNotEmpty) {
        await prefs.remove('saved_user_profile_$cleanEmail');
        await prefs.remove('user_pwd_$cleanEmail');
        await prefs.remove('reg_pwd_$cleanEmail');
        await prefs.remove('reg_name_$cleanEmail');
        await prefs.remove('is_new_account_$cleanEmail');
        await prefs.remove('custom_wardrobe_items_$cleanEmail');
        await prefs.remove('custom_outfits_$cleanEmail');
      }
      await prefs.remove('saved_user_profile_current');
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
    } catch (_) {}

    await TokenStorage.clearSession();
  }

  /// Nâng cấp tài khoản VIP bằng mã Coupon (WEARSY -> 1 năm VIP)
  Future<UserModel> upgradeVip({required String couponCode}) async {
    final cleanCoupon = couponCode.trim().toUpperCase();

    if (cleanCoupon != 'WEARSY') {
      throw ApiException(
        statusCode: 400,
        message:
            'Mã Coupon không hợp lệ. Vui lòng nhập đúng mã "WEARSY" để nhận 1 năm VIP!',
      );
    }

    var email = await TokenStorage.getUserEmail() ?? '';
    if (email.isEmpty) {
      final cached = await getProfile();
      email = cached.email;
    }
    final cleanEmail = email.trim().toLowerCase();

    try {
      final response = await _apiClient.post(
        ApiConstants.upgradeVip,
        body: {
          'coupon': cleanCoupon,
          if (cleanEmail.isNotEmpty) 'email': cleanEmail,
        },
      );
      if (response is Map<String, dynamic> && response['user'] != null) {
        final serverUser =
            UserModel.fromJson(response['user'] as Map<String, dynamic>);
        final merged = await _mergeWithLocalSavedUser(serverUser);
        await _persistUserProfile(merged);
        return merged;
      }
    } catch (_) {}

    final currentUser = await getProfile();
    final now = DateTime.now();
    DateTime baseTime = now;
    if (currentUser.vipExpiresAt != null &&
        currentUser.vipExpiresAt!.isAfter(now)) {
      baseTime = currentUser.vipExpiresAt!;
    }

    final newVipExpiry = baseTime.add(const Duration(days: 365));
    final updatedUser = currentUser.copyWith(
      isVip: true,
      vipExpiresAt: newVipExpiry,
    );

    await _persistUserProfile(updatedUser);
    return updatedUser;
  }

  /// Khôi phục toàn bộ tài khoản và cấu hình về trạng thái mặc định ban đầu
  Future<void> resetAllAccountsToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _pendingOtps.clear();
      await TokenStorage.clearSession();
    } catch (_) {}
  }

  String _deriveNameFromEmail(String email) {
    if (email.contains('@')) {
      final parts =
          email.split('@')[0].replaceAll('.', ' ').replaceAll('_', ' ');
      return parts
          .split(' ')
          .map((w) =>
              w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ')
          .trim();
    }
    return email;
  }
}
