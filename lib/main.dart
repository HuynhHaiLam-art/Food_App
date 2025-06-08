import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/providers/auth_provider.dart';
import 'package:food_app/screens/home_screen.dart';
import 'package:food_app/services/user_api_service.dart'; // <<--- THÊM IMPORT NÀY

void main() {
  // Khởi tạo UserApiService vì AuthProvider cần nó
  final userApiService = UserApiService(); // <<--- THAY ĐỔI Ở ĐÂY

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(userApiService), // <<--- CUNG CẤP UserApiService
        ),
        // Thêm các provider khác ở đây nếu cần
        // Ví dụ:
        // ChangeNotifierProvider(create: (_) => ProductProvider(ProductApiService())),
        // ChangeNotifierProvider(create: (_) => FavoriteProvider(FavoriteApiService(), userApiService)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Bạn có thể thử tự động đăng nhập ở đây nếu muốn,
    // nhưng tốt hơn là làm điều này trong một widget khởi tạo hoặc splash screen
    // để tránh gọi nó mỗi khi MyApp build lại.
    // Hoặc, nếu MyApp là StatefulWidget, gọi trong initState.
    // Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();

    return MaterialApp(
      title: 'King Burger',
      theme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF181A20), // Màu nền chính
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, // AppBar trong suốt để thấy background
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        colorScheme: ColorScheme.dark(
          primary: Colors.orange.shade700, // Màu chính cho button, accent
          secondary: Colors.pinkAccent.shade400, // Màu phụ
          surface: const Color(0xFF22252B), // Màu nền
          error: Colors.redAccent.shade400,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          onError: Colors.black,
          brightness: Brightness.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black.withOpacity(0.7),
          selectedItemColor: Colors.orange.shade700,
          unselectedItemColor: Colors.white60,
          type: BottomNavigationBarType.fixed,
        ),
        inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange.shade700, width: 1.5),
            ),
             prefixIconColor: Colors.white.withOpacity(0.5),
        ),
      ),
      // Sử dụng Consumer<AuthProvider> để quyết định màn hình ban đầu
      home: FutureBuilder(
        // Gọi tryAutoLogin một lần. listen: false là quan trọng ở đây.
        future: Provider.of<AuthProvider>(context, listen: false).tryAutoLogin(),
        builder: (ctx, authResultSnapshot) {
          // Trong khi tryAutoLogin đang chạy, hiển thị màn hình chờ
          if (authResultSnapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen(); // Màn hình chờ của bạn
          }
          // Sau khi tryAutoLogin hoàn tất, sử dụng Consumer để lắng nghe
          // các thay đổi trạng thái xác thực sau này (ví dụ: sau khi login/logout thủ công)
          return Consumer<AuthProvider>(
            builder: (context, auth, _) {
              // Nếu đã xác thực, đi đến HomeScreen
              // Nếu không, HomeScreen sẽ tự xử lý việc hiển thị LoginScreen nếu cần
              // hoặc bạn có thể điều hướng đến LoginScreen trực tiếp ở đây.
              return const HomeScreen();
              // Hoặc:
              // return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
            },
          );
        },
      ),
      debugShowCheckedModeBanner: false,
      // routes: { ... }
    );
  }
}

// Màn hình chờ đơn giản
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // <<--- THAY ĐỔI Ở ĐÂY
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.orange.shade700, // Bạn có thể giữ màu cam cho indicator hoặc đổi
        ),
      ),
    );
  }
}

// Nếu bạn muốn có màn hình chờ (splash screen) trong khi tryAutoLogin:
// class SplashScreen extends StatelessWidget {
//   const SplashScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       backgroundColor: Color(0xFF181A20),
//       body: Center(child: CircularProgressIndicator(color: Colors.orange)),
//     );
//   }
// }

// Để sử dụng cờ didTryAutoLogin trong AuthProvider:
// class AuthProvider with ChangeNotifier {
//   // ...
//   bool _didTryAutoLogin = false;
//   bool get didTryAutoLogin => _didTryAutoLogin;

//   Future<bool> tryAutoLogin() async {
//     _didTryAutoLogin = true; // Đặt cờ này ở đầu hàm
//     // ... logic còn lại của tryAutoLogin ...
//   }
//   // ...
// }