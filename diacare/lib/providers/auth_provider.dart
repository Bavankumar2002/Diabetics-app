import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _devOtp;
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isOnboarded = false;
  String _phoneNumber = '';
  String _countryCode = '+91';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get devOtp => _devOtp;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isOnboarded => _isOnboarded;
  String get phoneNumber => _phoneNumber;
  String get countryCode => _countryCode;

  Future<void> checkAuthStatus() async {
    final token = await ApiService.getToken();
    if (token != null && token.isNotEmpty) {
      _isAuthenticated = true;
      try {
        final res = await ApiService.get(ApiConstants.getProfile);
        if (res['success'] == true && res['data'] != null) {
          _currentUser = UserModel.fromJson(res['data']);
          _isOnboarded = true;
        } else {
          _isOnboarded = false;
        }
      } catch (_) {
        // Token might still be valid or server offline; keep session
      }
    } else {
      _isAuthenticated = false;
      _isOnboarded = false;
    }
    notifyListeners();
  }

  Future<bool> sendOtp(String phone, {String countryCode = '+91'}) async {
    _isLoading = true;
    _errorMessage = null;
    _devOtp = null;
    _phoneNumber = phone;
    _countryCode = countryCode;
    notifyListeners();

    try {
      final res = await ApiService.post(ApiConstants.sendOtp, {
        'phone': phone,
        'country_code': countryCode,
      });

      _isLoading = false;
      if (res['success'] == true) {
        if (res['data'] != null && res['data']['dev_otp'] != null) {
          _devOtp = res['data']['dev_otp'].toString();
        }
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Failed to send OTP';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String otp, {String countryCode = '+91'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(ApiConstants.verifyOtp, {
        'phone': phone,
        'country_code': countryCode,
        'otp': otp,
      });

      _isLoading = false;
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final token = data['auth_token'];
        if (token != null) {
          await ApiService.saveToken(token);
        }
        _isAuthenticated = true;
        _isOnboarded = data['is_onboarded'] == true;
        if (data['profile'] != null) {
          _currentUser = UserModel.fromJson(data['profile']);
        }
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Invalid OTP code';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveOnboardingProfile(Map<String, dynamic> profileData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(ApiConstants.saveProfile, profileData);
      _isLoading = false;

      if (res['success'] == true) {
        _isOnboarded = true;
        await refreshProfile();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Failed to save profile';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveReminders(List<Map<String, dynamic>> reminders) async {
    try {
      final res = await ApiService.post(ApiConstants.saveReminders, {
        'reminders': reminders,
      });
      return res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final res = await ApiService.get(ApiConstants.getProfile);
      if (res['success'] == true && res['data'] != null) {
        _currentUser = UserModel.fromJson(res['data']);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _currentUser = null;
    _isAuthenticated = false;
    _isOnboarded = false;
    _devOtp = null;
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    try {
      final res = await ApiService.post(ApiConstants.deleteAccount, {});
      if (res['success'] == true) {
        await logout();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
