import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/user_update.dart';
import '../services/user_api_service.dart';

class AuthProvider with ChangeNotifier {
  final UserApiService _userApiService;
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get lastErrorMessage => _errorMessage;
  
  bool get isLoggedIn => _currentUser != null && _token != null;
  bool get isAuthenticated => _currentUser != null && _token != null;
  bool get isAdmin => _currentUser?.role == 'Admin';
  bool get isUser => _currentUser?.role == 'User';

  AuthProvider(this._userApiService) {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      final token = prefs.getString('token');
      
      print('📱 Loading from storage - User: $userJson');
      print('📱 Loading from storage - Token: $token');
      
      if (userJson != null && token != null) {
        _currentUser = User.fromJson(json.decode(userJson));
        _token = token;
        notifyListeners();
        print('🔄 Loaded user from storage: ${_currentUser?.name} (${_currentUser?.role})');
        print('🎫 Loaded token: ${_token?.substring(0, 20)}...');
      } else {
        print('❌ No user data found in storage');
      }
    } catch (e) {
      print('❌ Error loading user from storage: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      print('🔐 Attempting login for: $email');
      
      final response = await _userApiService.login(email, password);
      print('📥 Login response: $response');
      
      // ✅ SỬA: Parse response structure đúng
      if (response.containsKey('data')) {
        final data = response['data'];
        _token = data['token'];
        _currentUser = User.fromJson(data['user']);
      } else if (response.containsKey('token')) {
        _token = response['token'];
        if (response.containsKey('user')) {
          _currentUser = User.fromJson(response['user']);
        } else {
          // Nếu không có user object, tạo từ response
          _currentUser = User.fromJson(response);
        }
      } else {
        // Fallback - toàn bộ response là user data
        _currentUser = User.fromJson(response);
        _token = response['token'] ?? 'dummy_token'; // Fallback token
      }

      // ✅ QUAN TRỌNG: Save to storage ngay lập tức
      if (_currentUser != null && _token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_currentUser!.toJson()));
        await prefs.setString('token', _token!);
        
        print('💾 Saved to storage - User: ${_currentUser?.name}');
        print('💾 Saved to storage - Token: ${_token?.substring(0, 20)}...');
      }

      print('✅ Login successful: ${_currentUser?.name} (${_currentUser?.role})');
      print('🎫 Token: ${_token?.substring(0, 20)}...');
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Login failed: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final response = await _userApiService.register(name, email, password);
      
      if (response.containsKey('data')) {
        final data = response['data'];
        _token = data['token'];
        _currentUser = User.fromJson(data['user']);
      } else if (response.containsKey('token')) {
        _token = response['token'];
        _currentUser = User.fromJson(response['user'] ?? response);
      } else {
        _currentUser = User.fromJson(response);
        _token = response['token'] ?? 'dummy_token';
      }

      // Save to storage
      if (_currentUser != null && _token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_currentUser!.toJson()));
        await prefs.setString('token', _token!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserProfile(UserUpdate userUpdate, {String? oldPassword, String? newPassword}) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      if (_currentUser?.id == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      final updatedUser = User(
        id: _currentUser!.id,
        name: userUpdate.name ?? _currentUser!.name,
        email: _currentUser!.email,
        role: _currentUser!.role,
      );

      final result = await _userApiService.updateUser(_currentUser!.id!, updatedUser, token: _token);
      
      if (oldPassword != null && newPassword != null && oldPassword.isNotEmpty && newPassword.isNotEmpty) {
        await _userApiService.changePassword(_currentUser!.id!, oldPassword, newPassword, token: _token);
      }

      _currentUser = result;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(_currentUser!.toJson()));

      print('✅ Profile updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Profile update failed: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshCurrentUser() async {
    try {
      if (_currentUser?.id == null || _token == null) return;

      final updatedUser = await _userApiService.getUserById(_currentUser!.id!, token: _token);
      _currentUser = updatedUser;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(_currentUser!.toJson()));

      notifyListeners();
      print('🔄 User data refreshed: ${_currentUser?.name}');
    } catch (e) {
      print('❌ Error refreshing user data: $e');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      await prefs.remove('token');
      
      _currentUser = null;
      _token = null;
      _errorMessage = null;
      
      print('👋 User logged out successfully');
      notifyListeners();
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}