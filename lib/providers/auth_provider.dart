import 'dart:async'; // For Timer
import 'dart:convert'; // Để mã hóa và giải mã JSON (nếu lưu user data vào SharedPreferences)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Để lưu trữ token/user data

import 'package:food_app/services/user_api_service.dart';
import 'package:food_app/models/login.dart'; // Sử dụng LoginDTO từ models/login.dart
import 'package:food_app/models/register.dart'; // Sử dụng RegisterDTO từ models/register.dart
import 'package:food_app/models/user.dart'; // Sử dụng User từ models/user.dart
import 'package:food_app/models/user_update.dart';


class AuthProvider with ChangeNotifier {
  final UserApiService _userApiService;

  String? _token;
  User? _currentUser;
  DateTime? _expiryDate;
  Timer? _authTimer;
  String? _lastErrorMessage;

  bool _didTryAutoLogin = false; // <<--- TRƯỜNG NÀY ĐÃ CÓ

  static const String _userDataKey = 'userData';

  AuthProvider(this._userApiService) {
    // Cân nhắc gọi tryAutoLogin ở đây nếu bạn muốn nó chạy ngay khi provider được tạo
    // và trước khi widget đầu tiên build.
    // Tuy nhiên, làm vậy có thể khiến UI "nhảy" nếu tryAutoLogin mất thời gian.
    // Sử dụng FutureBuilder hoặc Splash Screen trong main.dart thường tốt hơn.
  }

  bool get isAuthenticated {
    return token != null;
  }

  String? get token {
    if (_expiryDate != null && _expiryDate!.isAfter(DateTime.now()) && _token != null) {
      return _token;
    }
    return null;
  }

  User? get currentUser {
    return _currentUser;
  }

  int? get userId {
    // Đảm bảo rằng ID trả về là int, vì User model có id là int?
    // Nếu API trả về ID dạng String, User.fromJson cần xử lý việc chuyển đổi.
    return _currentUser?.id;
  }

  String? get lastErrorMessage => _lastErrorMessage;

  bool get didTryAutoLogin => _didTryAutoLogin; // <<--- GETTER NÀY ĐÃ CÓ

  void _clearErrorMessage() {
    _lastErrorMessage = null;
    // Không cần notifyListeners() ở đây trừ khi bạn muốn UI phản ứng với việc xóa lỗi
  }

  Future<bool> login(LoginDTO loginData) async {
    _clearErrorMessage();
    try {
      final responseData = await _userApiService.login(loginData);
      // UserApiService.login giờ sẽ ném lỗi nếu thất bại,
      // nên nếu đến được đây, responseData được đảm bảo là hợp lệ.

      _token = responseData['token'] as String?;
      
      // UserApiService.login đã đảm bảo 'user' là một Map nếu có
      final userMap = responseData['user'] as Map<String, dynamic>?;
      if (userMap != null) {
        _currentUser = User.fromJson(userMap);
      } else {
         // Trường hợp hiếm, nếu API trả về token mà không có user data đầy đủ
         // Cần xem xét lại logic này dựa trên API thực tế
        _currentUser = User(email: loginData.email); // Tạm thời, chỉ có email
        print("AuthProvider: User data missing in login response, but token received.");
      }

      // Xử lý expiresIn - API có thể trả về String hoặc int
      final expiresIn = responseData['expiresIn']; 
      if (expiresIn != null) {
        final expiresInSeconds = int.tryParse(expiresIn.toString());
        if (expiresInSeconds != null) {
          _expiryDate = DateTime.now().add(Duration(seconds: expiresInSeconds));
          _autoLogout(); // Thiết lập tự động logout
        } else {
          print("AuthProvider: Không thể phân tích expiresIn từ API: $expiresIn");
          // Có thể đặt một thời gian hết hạn mặc định nếu cần
          // _expiryDate = DateTime.now().add(const Duration(hours: 1)); 
        }
      } else {
        print("AuthProvider: Không có thông tin expiresIn từ API.");
        // Có thể đặt một thời gian hết hạn mặc định nếu cần
        // _expiryDate = DateTime.now().add(const Duration(hours: 1));
      }
      
      notifyListeners();
      await _saveAuthDataToPrefs(); // Lưu thông tin xác thực
      return true;
    } catch (error) {
      print('Login error in AuthProvider: $error');
      _lastErrorMessage = error.toString();
      notifyListeners(); // Thông báo lỗi để UI có thể cập nhật
      return false;
    }
  }

  Future<bool> register(RegisterDTO registerData) async {
    _clearErrorMessage();
    try {
      final responseData = await _userApiService.register(registerData);
      // UserApiService.register giờ sẽ ném lỗi nếu thất bại.

      // Kiểm tra xem API có trả về token và user (tự động đăng nhập sau khi đăng ký) không
      if (responseData.containsKey('token') && responseData.containsKey('user')) {
        _token = responseData['token'] as String?;
        final userMap = responseData['user'] as Map<String, dynamic>?;
         if (userMap != null) {
          _currentUser = User.fromJson(userMap);
        } else {
          // Xử lý trường hợp userMap là null nếu có thể xảy ra
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
        return true; // Đăng ký và đăng nhập thành công
      } else if (responseData.containsKey('message')) {
        // Đăng ký thành công nhưng không tự động đăng nhập, API trả về message
        // Thông báo này có thể là "Đăng ký thành công. Vui lòng đăng nhập."
        _lastErrorMessage = responseData['message'] as String?; 
        notifyListeners();
        // Trả về true vì đăng ký thành công, dù chưa đăng nhập.
        // UI có thể dựa vào _lastErrorMessage để hiển thị thông báo.
        return true; 
      }
      // Trường hợp response không mong muốn từ API
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
    _lastErrorMessage = null; // Reset lỗi trước khi thử
    notifyListeners(); // Thông báo để UI có thể xóa lỗi cũ (nếu cần)

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
        // Cập nhật thành công, làm mới thông tin người dùng hiện tại
        await refreshCurrentUser(); // Hàm này cũng nên có try-catch và notifyListeners
        _lastErrorMessage = null; // Xóa lỗi nếu thành công
        notifyListeners();
        return true;
      } else {
        // _userApiService đã ném lỗi và được bắt ở dưới, hoặc trả về false với message
        // Nếu _userApiService trả về false mà không ném lỗi, bạn cần tự set message
        // _lastErrorMessage = "Cập nhật thất bại từ API."; // Ví dụ
        // (Hiện tại UserApiService ném Exception nên sẽ vào khối catch)
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
    if (!isAuthenticated) return; // Không thể làm mới nếu không có token hợp lệ
    _clearErrorMessage();
    try {
      final updatedUser = await _userApiService.getCurrentUserDetails(_token!);
      _currentUser = updatedUser;
      // Cập nhật lại expiryDate nếu API trả về (hiếm khi cho refresh) hoặc giữ nguyên
      // Nếu logic token của bạn phức tạp (ví dụ: refresh token), bạn có thể cần cập nhật _expiryDate ở đây
      notifyListeners();
      await _saveAuthDataToPrefs(); // Lưu lại thông tin người dùng đã cập nhật
    } catch (error) {
      print('Refresh current user error in AuthProvider: $error');
      _lastErrorMessage = error.toString();
      // Cân nhắc: có nên logout nếu refresh thất bại không?
      // Ví dụ: nếu token không còn hợp lệ hoặc API trả về lỗi 401.
      // if (error.toString().contains('401') || error.toString().toLowerCase().contains('unauthorized')) {
      //   await logout();
      // }
      notifyListeners();
    }
  }


  Future<void> _saveAuthDataToPrefs() async {
    // Chỉ lưu nếu có token và user, hoặc chỉ token nếu user có thể null tạm thời
    if (_token == null) {
      // Nếu không có token, đảm bảo xóa dữ liệu cũ
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      print("AuthProvider: Token is null, removed user data from prefs.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    // Đảm bảo tất cả các giá trị là String hoặc kiểu nguyên thủy có thể encode
    final userData = json.encode({
      'token': _token,
      'userId': _currentUser?.id, // id là int?
      'email': _currentUser?.email,
      'name': _currentUser?.name,
      'role': _currentUser?.role,
      'expiryDate': _expiryDate?.toIso8601String(), // Chuyển DateTime thành String
    });
    await prefs.setString(_userDataKey, userData);
    print("AuthProvider: Saved user data to prefs. Token: ${_token != null}, UserID: ${_currentUser?.id}");
  }

  Future<bool> tryAutoLogin() async {
    _didTryAutoLogin = true; // <<--- ĐẶT CỜ NÀY Ở ĐẦU HÀM
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_userDataKey)) {
      print("AuthProvider (tryAutoLogin): No user data found in prefs.");
      notifyListeners(); // Thông báo để Consumer biết _didTryAutoLogin đã thay đổi
      return false;
    }

    final extractedUserDataString = prefs.getString(_userDataKey);
    if (extractedUserDataString == null) {
      print("AuthProvider (tryAutoLogin): User data string is null in prefs.");
      await prefs.remove(_userDataKey); // Xóa key hỏng
      notifyListeners();
      return false;
    }
    
    Map<String, dynamic> extractedUserData;
    try {
      extractedUserData = json.decode(extractedUserDataString) as Map<String, dynamic>;
    } catch (e) {
      print("AuthProvider (tryAutoLogin): Error decoding user data from prefs: $e");
      await prefs.remove(_userDataKey); // Xóa key hỏng
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
      await prefs.remove(_userDataKey); // Xóa dữ liệu đã hết hạn
      notifyListeners();
      return false;
    }

    _token = extractedUserData['token'] as String?;
    // Kiểm tra null cho các trường của User trước khi gán
    _currentUser = User(
      id: extractedUserData['userId'] as int?, // id là int?
      name: extractedUserData['name'] as String?,
      email: extractedUserData['email'] as String?,
      role: extractedUserData['role'] as String?,
    );
    _expiryDate = expiryDate;
    
    print("AuthProvider (tryAutoLogin): Auto login successful. UserID: ${_currentUser?.id}");
    notifyListeners();
    _autoLogout(); // Thiết lập lại timer tự động logout
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _expiryDate = null;
    _lastErrorMessage = null; // Xóa thông báo lỗi khi logout
    if (_authTimer != null) {
      _authTimer!.cancel();
      _authTimer = null;
    }
    
    final prefs = await SharedPreferences.getInstance();
    // Có thể chỉ remove key cụ thể hoặc clear toàn bộ nếu cần
    await prefs.remove(_userDataKey);
    // await prefs.clear(); // Nếu muốn xóa tất cả SharedPreferences

    print("AuthProvider: User logged out.");
    notifyListeners(); // Quan trọng: thông báo cho UI biết đã logout
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