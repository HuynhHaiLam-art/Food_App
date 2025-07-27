import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class UserApiService {
  static const String _baseUrl = 'http://localhost:5062/api/User';
  static const Duration _timeoutDuration = Duration(seconds: 20); // ✅ Tăng timeout

  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ✅ Login - unchanged
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: _getHeaders(),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(_timeoutDuration);

      print('🔐 Login Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Đăng nhập thất bại: ${response.body}');
      }
    } catch (e) {
      print('❌ Login Error: $e');
      rethrow;
    }
  }

  // ✅ Register - unchanged  
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: _getHeaders(),
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'role': 'User',
        }),
      ).timeout(_timeoutDuration);

      print('📝 Register Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Đăng ký thất bại: ${response.body}');
      }
    } catch (e) {
      print('❌ Register Error: $e');
      rethrow;
    }
  }

  // ✅ Get all users
  Future<List<User>> getAllUsers({String? token}) async {
    try {
      print('🔍 Getting all users...');
      
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: _getHeaders(token: token),
      ).timeout(_timeoutDuration);

      print('👥 Users Response: ${response.statusCode}');
      print('👥 Response Body Length: ${response.body.length}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Loaded ${data.length} users');
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Get users failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ GetAllUsers Error: $e');
      rethrow;
    }
  }

  // ✅ FIX: Create user - match UserCreateDTO
  Future<User> createUser(User user, String password, {String? token}) async {
    try {
      print('➕ Creating user: ${user.name}');
      
      final userData = {
        'name': user.name,
        'email': user.email,
        'password': password,
        'role': user.role ?? 'User',
      };

      print('📤 User create data: $userData');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _getHeaders(token: token),
        body: json.encode(userData),
      ).timeout(_timeoutDuration);

      print('👤 Create User Response: ${response.statusCode}');
      print('👤 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Create user failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ CreateUser Error: $e');
      rethrow;
    }
  }

  // ✅ FIX: Update user - match UserUpdateDTO
  Future<User> updateUser(int id, User user, {String? token}) async {
    try {
      print('✏️ Updating user $id');
      
      final userData = <String, dynamic>{
        'name': user.name,
        'email': user.email,
      };

      // ✅ Only add role if it's provided and not null
      if (user.role != null && user.role!.isNotEmpty) {
        userData['role'] = user.role;
      }

      print('📤 User update data: $userData');

      final response = await http.put(
        Uri.parse('$_baseUrl/$id'),
        headers: _getHeaders(token: token),
        body: json.encode(userData),
      ).timeout(_timeoutDuration);

      print('🔄 Update User Response: ${response.statusCode}');
      print('🔄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ User updated successfully');
        return user.copyWith(id: id);
      } else {
        throw Exception('Update user failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ UpdateUser Error: $e');
      rethrow;
    }
  }

  // ✅ FIX: Delete user
  Future<void> deleteUser(int userId, {String? token}) async {
    print('🔗 Deleting user $userId');
    
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$userId'),
        headers: _getHeaders(token: token),
      ).timeout(_timeoutDuration);

      print('❌ Delete User Response: ${response.statusCode}');
      print('❌ Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 404) {
        print('✅ User deleted successfully');
        return;
      } else {
        throw Exception('Delete user failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ DeleteUser Error: $e');
      rethrow;
    }
  }

  // ✅ Other methods
  Future<User> getUserById(int id, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: _getHeaders(token: token),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Get user failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/check-email?email=$email'),
        headers: _getHeaders(),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['exists'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> changePassword(int userId, String oldPassword, String newPassword, {String? token}) async {
    try {
      final userData = {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      };

      final response = await http.put(
        Uri.parse('$_baseUrl/$userId'),
        headers: _getHeaders(token: token),
        body: json.encode(userData),
      ).timeout(_timeoutDuration);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Đổi mật khẩu thất bại: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Forgot password methods
  Future<Map<String, dynamic>> sendForgotPasswordCode(String email) async {
    try {
      print('📧 Sending forgot password code to: $email');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/forgot-password'),
        headers: _getHeaders(),
        body: json.encode({
          'email': email,
        }),
      ).timeout(_timeoutDuration);

      print('📧 Forgot Password Response: ${response.statusCode}');
      print('📧 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Gửi mã thất bại');
      }
    } catch (e) {
      print('❌ Send Reset Code Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    try {
      print('🔐 Verifying reset code for: $email');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/verify-reset-code'),
        headers: _getHeaders(),
        body: json.encode({
          'email': email,
          'code': code,
        }),
      ).timeout(_timeoutDuration);

      print('🔐 Verify Code Response: ${response.statusCode}');
      print('🔐 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Mã xác nhận không đúng');
      }
    } catch (e) {
      print('❌ Verify Reset Code Error: $e');
      rethrow;
    }
  }
}
