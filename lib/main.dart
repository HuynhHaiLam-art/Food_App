import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/providers/auth_provider.dart';
import 'package:food_app/providers/product_provider.dart';
import 'package:food_app/providers/favorite_provider.dart';
import 'package:food_app/services/user_api_service.dart';
import 'package:food_app/widgets/home/main_nav_widget.dart'; // Sử dụng widget quản lý tab

void main() {
  final userApiService = UserApiService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(userApiService),
        ),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()), // <-- Thêm dòng này
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'King Burger',
      theme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF181A20),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        colorScheme: ColorScheme.dark(
          primary: Colors.orange.shade700,
          secondary: Colors.pinkAccent.shade400,
          surface: const Color(0xFF22252B),
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
      home: FutureBuilder(
        future: Provider.of<AuthProvider>(context, listen: false).tryAutoLogin(),
        builder: (ctx, authResultSnapshot) {
          if (authResultSnapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          return Consumer<AuthProvider>(
            builder: (context, auth, _) {
              // Nếu muốn điều hướng cứng sang LoginScreen khi chưa đăng nhập:
              // return auth.isAuthenticated ? const MainNavWidget() : const LoginScreen();
              // Nếu muốn MainNavWidget tự xử lý logic đăng nhập, giữ như dưới:
              return const MainNavWidget();
            },
          );
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo hoặc icon app
            Icon(Icons.fastfood, size: 64, color: Colors.orange.shade700),
            const SizedBox(height: 24),
            Text(
              'King Burger',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 28,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              color: Colors.orange.shade700,
            ),
          ],
        ),
      ),
    );
  }
}

