import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Thêm Provider
import '../providers/auth_provider.dart'; // Thêm AuthProvider
import '../models/register.dart'; // Giữ lại RegisterDTO
import '../models/login.dart'; // Giữ lại LoginDTO

// Bỏ final userApi = UserApiService(); // AuthProvider sẽ xử lý việc này

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String password = '';
  bool isLoading = false;
  bool showPassword = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save(); // Cần thiết nếu bạn dùng onSaved trong TextFormField

    setState(() => isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;

    try {
      if (isLogin) {
        print('LoginScreen: Đang thử đăng nhập với Email: "$email", Password: "$password"'); // DEBUG
        final loginDto = LoginDTO(email: email, password: password);
        success = await authProvider.login(loginDto);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng nhập thành công!'), backgroundColor: Colors.green),
          );
          if (mounted) {
            // Pop màn hình login và trả về true để báo hiệu đăng nhập thành công
            Navigator.pop(context, true); 
          }
        } else {
          // Lấy thông báo lỗi cụ thể từ AuthProvider
          final errorMessage = authProvider.lastErrorMessage ?? 'Email hoặc mật khẩu không đúng.';
          print('LoginScreen: Đăng nhập thất bại. Lỗi từ AuthProvider: $errorMessage'); // DEBUG
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng nhập thất bại: $errorMessage'), backgroundColor: Colors.red),
          );
        }
      } else {
        print('LoginScreen: Đang thử đăng ký với Tên: "$name", Email: "$email", Password: "$password"'); // DEBUG
        final registerDto = RegisterDTO(
          name: name,
          email: email,
          password: password,
        );
        success = await authProvider.register(registerDto);
        if (success) {
          // Kiểm tra xem có thông báo thành công từ AuthProvider không (ví dụ: "Đăng ký thành công. Vui lòng đăng nhập.")
          final successMessage = authProvider.lastErrorMessage ?? 'Đăng ký thành công! Bạn có thể đăng nhập ngay.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
          );
          setState(() {
            isLogin = true; 
          });
        } else {
          final errorMessage = authProvider.lastErrorMessage ?? 'Email có thể đã tồn tại hoặc lỗi không xác định.';
          print('LoginScreen: Đăng ký thất bại. Lỗi từ AuthProvider: $errorMessage'); // DEBUG
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng ký thất bại: $errorMessage'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (error) {
      print('LoginScreen: Lỗi không mong muốn trong _submitForm: ${error.toString()}'); // DEBUG
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: ${error.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Ẩn bàn phím khi bấm ngoài
        child: Stack(
          children: [
            // Background ảnh mờ
            Positioned.fill(
              child: Image.asset(
                'assets/images/background.jpg', // Đảm bảo bạn có ảnh này
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.55), // Tăng độ mờ để dễ đọc chữ hơn
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [ // Thêm hiệu ứng đổ bóng nhẹ
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ]
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Nút back về Home
                            Align(
                              alignment: Alignment.topLeft,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Icon(Icons.food_bank_outlined, color: Colors.white, size: 60), // <<--- THAY ĐỔI: Icon màu trắng
                            const SizedBox(height: 16),
                            Text(
                              isLogin ? 'Đăng nhập' : 'Tạo tài khoản',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28, // Tăng kích thước chữ
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (!isLogin)
                              TextFormField(
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Tên của bạn',
                                  hintStyle: const TextStyle(color: Colors.white54),
                                  prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.08),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                ),
                                onChanged: (value) => name = value.trim(),
                                validator: (value) {
                                  if (!isLogin && (value == null || value.trim().isEmpty)) {
                                    return 'Vui lòng nhập tên';
                                  }
                                  return null;
                                },
                              ),
                            if (!isLogin) const SizedBox(height: 16),
                            TextFormField(
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: const TextStyle(color: Colors.white54),
                                prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.08),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) => email = value.trim(),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập email';
                                }
                                if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value.trim())) {
                                  return 'Email không hợp lệ';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              obscureText: !showPassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Mật khẩu',
                                hintStyle: const TextStyle(color: Colors.white54),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      showPassword = !showPassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.08),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              ),
                              onChanged: (value) => password = value,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập mật khẩu';
                                }
                                if (value.length < 6) {
                                  return 'Mật khẩu phải có ít nhất 6 ký tự';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton( // <<--- THAY ĐỔI: Sử dụng OutlinedButton
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white, // Chữ màu trắng
                                  side: BorderSide(color: Colors.white.withOpacity(0.8), width: 1.5), // Viền trắng
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle( // Thêm textStyle cho OutlinedButton
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: isLoading ? null : _submitForm,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Text(
                                        isLogin ? 'Đăng nhập' : 'Đăng ký',
                                        // TextStyle ở đây không cần nữa nếu đã set trong OutlinedButton.styleFrom
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  isLogin = !isLogin;
                                  _formKey.currentState?.reset(); // Reset form khi chuyển tab
                                });
                              },
                              child: Text(
                                isLogin
                                    ? 'Chưa có tài khoản? Đăng ký ngay'
                                    : 'Đã có tài khoản? Đăng nhập',
                                style: TextStyle( // <<--- THAY ĐỔI: TextButton màu trắng
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}