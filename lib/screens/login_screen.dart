import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/register.dart';
import '../models/login.dart';
import '../widgets/home/background_widget.dart';
import '../widgets/home/main_nav_widget.dart'; // Thêm import này

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
  String confirmPassword = '';
  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false; // Thêm biến này

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;

    try {
      if (isLogin) {
        final loginDto = LoginDTO(email: email, password: password);
        success = await authProvider.login(loginDto);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng nhập thành công!'), backgroundColor: Colors.green),
          );
          // Chuyển về MainNavWidget và sang tab Profile (index 3)
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const MainNavWidget(initialTab: 3), // Truyền tab Cá nhân
              ),
              (route) => false,
            );
          }
        } else {
          final errorMessage = authProvider.lastErrorMessage ?? 'Email hoặc mật khẩu không đúng.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng nhập thất bại: $errorMessage'), backgroundColor: Colors.red),
          );
        }
      } else {
        final registerDto = RegisterDTO(
          name: name,
          email: email,
          password: password,
        );
        success = await authProvider.register(registerDto);
        if (success) {
          final successMessage = authProvider.lastErrorMessage ?? 'Đăng ký thành công! Bạn có thể đăng nhập ngay.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
          );
          setState(() {
            isLogin = true;
            name = '';
            email = '';
            password = '';
            confirmPassword = '';
            _formKey.currentState?.reset();
          });
        } else {
          final errorMessage = authProvider.lastErrorMessage ?? 'Email có thể đã tồn tại hoặc lỗi không xác định.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng ký thất bại: $errorMessage'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: ${error.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _switchMode() {
    setState(() {
      isLogin = !isLogin;
      name = '';
      email = '';
      password = '';
      confirmPassword = '';
      _formKey.currentState?.reset();
    });
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavWidget(initialTab: 0)), // Tab Home
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
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
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                              onPressed: isLoading ? null : _goHome, // Sửa lại hàm này
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Icon(Icons.food_bank_outlined, color: Colors.white, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            isLogin ? 'Đăng nhập' : 'Tạo tài khoản',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
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
                          // Thêm trường nhập lại mật khẩu khi đăng ký
                          if (!isLogin) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              obscureText: !showConfirmPassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Nhập lại mật khẩu',
                                hintStyle: const TextStyle(color: Colors.white54),
                                prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    showConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      showConfirmPassword = !showConfirmPassword;
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
                              onChanged: (value) => confirmPassword = value,
                              validator: (value) {
                                if (!isLogin && (value == null || value.isEmpty)) {
                                  return 'Vui lòng nhập lại mật khẩu';
                                }
                                if (!isLogin && value != password) {
                                  return 'Mật khẩu nhập lại không khớp';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withOpacity(0.8), width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(
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
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: isLoading ? null : _switchMode,
                            child: Text(
                              isLogin
                                  ? 'Chưa có tài khoản? Đăng ký ngay'
                                  : 'Đã có tài khoản? Đăng nhập',
                              style: TextStyle(
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
        ),
      ),
    );
  }
}