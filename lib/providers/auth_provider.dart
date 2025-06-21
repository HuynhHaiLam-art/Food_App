import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:food_app/services/user_api_service.dart';
import 'package:food_app/models/login.dart';
import 'package:food_app/models/register.dart';
import 'package:food_app/models/user.dart';
import 'package:food_app/models/user_update.dart';

class AuthProvider with ChangeNotifier {
  final UserApiService _userApiService;

  String? _token;
  User? _currentUser;
  DateTime? _expiryDate;
  Timer? _authTimer;
  String? _lastErrorMessage;
  bool _didTryAutoLogin = false;

  static const String _userDataKey = 'userData';

  AuthProvider(this._userApiService);

  bool get isAuthenticated => token != null;

  String? get token {
    if (_expiryDate != null && _expiryDate!.isAfter(DateTime.now()) && _token != null) {
      return _token;
    }
    return null;
  }

  User? get currentUser => _currentUser;

  int? get userId => _currentUser?.id;

  String? get lastErrorMessage => _lastErrorMessage;

  bool get didTryAutoLogin => _didTryAutoLogin;

  void _clearErrorMessage() {
    _lastErrorMessage = null;
  }

  Future<bool> login(LoginDTO loginData) async {
    _clearErrorMessage();
    try {
      final responseData = await _userApiService.login(loginData);
      _token = responseData['token'] as String?;
      final userMap = responseData['user'] as Map<String, dynamic>?;
      if (userMap != null) {
        _currentUser = User.fromJson(userMap);
      } else {
        _currentUser = User(email: loginData.email);
        print("AuthProvider: User data missing in login response, but token received.");
      }
      final expiresIn = responseData['expiresIn'];
      if (expiresIn != null) {
        final expiresInSeconds = int.tryParse(expiresIn.toString());
        if (expiresInSeconds != null) {
          _expiryDate = DateTime.now().add(Duration(seconds: expiresInSeconds));
          _autoLogout();
        }
      }
      notifyListeners();
      await _saveAuthDataToPrefs();
      return true;
    } catch (error) {
      print('Login error in AuthProvider: $error');
      _lastErrorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(RegisterDTO registerData) async {
    _clearErrorMessage();
    try {
      final responseData = await _userApiService.register(registerData);
      if (responseData.containsKey('token') && responseData.containsKey('user')) {
        _token = responseData['token'] as String?;
        final userMap = responseData['user'] as Map<String, dynamic>?;
        if (userMap != null) {
          _currentUser = User.fromJson(userMap);
        } else {
          print("AuthProvider (Register): User data missing in response, but token received.");
        }
        final expiresIn = responseData['expiresIn'];
        if (expiresIn != null) {
          final expiresInSeconds = int.tryParse(expiresIn.toString());
          if (expiresInSeconds != null) {
            _expiryDate = DateTime.now().add(Duration(seconds: expiresInSeconds));
            _autoLogout();
          }
        }
        notifyListeners();
        await _saveAuthDataToPrefs();
        return true;
      } else if (responseData.containsKey('message')) {
        _lastErrorMessage = responseData['message'] as String?;
        notifyListeners();
        return true;
      }
      _lastErrorMessage = "Phản hồi đăng ký không hợp lệ từ máy chủ.";
      notifyListeners();
      return false;
    } catch (error) {
      print('Register error in AuthProvider: $error');
      _lastErrorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUserProfile(UserUpdate userUpdateData, {String? oldPassword, String? newPassword}) async {
    _lastErrorMessage = null;
    notifyListeners();

    if (!isAuthenticated || _currentUser?.id == null) {
      _lastErrorMessage = "Người dùng chưa đăng nhập hoặc thiếu thông tin ID.";
      notifyListeners();
      return false;
    }
    try {
      final success = await _userApiService.updateUserProfile(
        _currentUser!.id!,
        userUpdateData,
        oldPassword: oldPassword,
        newPassword: newPassword,
        token: _token!,
      );
      if (success) {
        await refreshCurrentUser();
        _lastErrorMessage = null;
        notifyListeners();
        return true;
      } else {
        notifyListeners();
        return false;
      }
    } catch (error) {
      print('AuthProvider updateUserProfile error: $error');
      _lastErrorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshCurrentUser() async {
    if (!isAuthenticated) return;
    _clearErrorMessage();
    try {
      final updatedUser = await _userApiService.getCurrentUserDetails(_token!);
      _currentUser = updatedUser;
      notifyListeners();
      await _saveAuthDataToPrefs();
    } catch (error) {
      print('Refresh current user error in AuthProvider: $error');
      _lastErrorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> _saveAuthDataToPrefs() async {
    if (_token == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      print("AuthProvider: Token is null, removed user data from prefs.");
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final userData = json.encode({
      'token': _token,
      'userId': _currentUser?.id,
      'email': _currentUser?.email,
      'name': _currentUser?.name,
      'role': _currentUser?.role,
      'expiryDate': _expiryDate?.toIso8601String(),
    });
    await prefs.setString(_userDataKey, userData);
    print("AuthProvider: Saved user data to prefs. Token: ${_token != null}, UserID: ${_currentUser?.id}");
  }

  Future<bool> tryAutoLogin() async {
    _didTryAutoLogin = true;
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_userDataKey)) {
      print("AuthProvider (tryAutoLogin): No user data found in prefs.");
      notifyListeners();
      return false;
    }
    final extractedUserDataString = prefs.getString(_userDataKey);
    if (extractedUserDataString == null) {
      print("AuthProvider (tryAutoLogin): User data string is null in prefs.");
      await prefs.remove(_userDataKey);
      notifyListeners();
      return false;
    }
    Map<String, dynamic> extractedUserData;
    try {
      extractedUserData = json.decode(extractedUserDataString) as Map<String, dynamic>;
    } catch (e) {
      print("AuthProvider (tryAutoLogin): Error decoding user data from prefs: $e");
      await prefs.remove(_userDataKey);
      notifyListeners();
      return false;
    }
    final expiryDateString = extractedUserData['expiryDate'] as String?;
    DateTime? expiryDate;
    if (expiryDateString != null) {
      expiryDate = DateTime.tryParse(expiryDateString);
    }
    if (expiryDate == null || expiryDate.isBefore(DateTime.now())) {
      print("AuthProvider (tryAutoLogin): Token expired or expiryDate invalid.");
      _token = null;
      _currentUser = null;
      _expiryDate = null;
      if (_authTimer != null) {
        _authTimer!.cancel();
        _authTimer = null;
      }
      await prefs.remove(_userDataKey);
      notifyListeners();
      return false;
    }
    _token = extractedUserData['token'] as String?;
    _currentUser = User(
      id: extractedUserData['userId'] as int?,
      name: extractedUserData['name'] as String?,
      email: extractedUserData['email'] as String?,
      role: extractedUserData['role'] as String?,
    );
    _expiryDate = expiryDate;
    print("AuthProvider (tryAutoLogin): Auto login successful. UserID: ${_currentUser?.id}");
    notifyListeners();
    _autoLogout();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _expiryDate = null;
    _lastErrorMessage = null;
    if (_authTimer != null) {
      _authTimer!.cancel();
      _authTimer = null;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
    print("AuthProvider: User logged out.");
    notifyListeners();
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }
    if (_expiryDate == null) return;
    final timeToExpiry = _expiryDate!.difference(DateTime.now()).inSeconds;
    if (timeToExpiry <= 0) {
      print("AuthProvider (_autoLogout): Token already expired, logging out.");
      logout();
      return;
    }
    _authTimer = Timer(Duration(seconds: timeToExpiry), () {
      print("AuthProvider (_autoLogout): Auth timer expired, logging out.");
      logout();
    });
  }
}