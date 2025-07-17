import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:food_app/providers/auth_provider.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/providers/favorite_provider.dart';
import 'package:food_app/providers/product_provider.dart';
import 'package:food_app/services/user_api_service.dart';
import 'package:food_app/services/product_api_service.dart';
import 'package:food_app/widgets/home/main_nav_widget.dart';
import 'package:food_app/screens/admin_dashboard_screen.dart';
import 'package:food_app/screens/checkout_screen.dart'; // ✅ Import CheckoutScreen
import 'package:food_app/themes/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✨ Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(UserApiService()),
        ),
        ChangeNotifierProvider(
          create: (context) => CartProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => FavoriteProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ProductProvider(ProductApiService()),
        ),
      ],
      child: MaterialApp(
        title: 'King Burger',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        home: const AuthWrapper(),
        // ✅ Thêm routes để support navigation
        routes: {
          '/checkout': (context) => const CheckoutScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
          '/home': (context) => const MainNavWidget(),
        },
        // ✅ Thêm onGenerateRoute để handle unknown routes
        onGenerateRoute: (settings) {
          print('📍 Navigating to: ${settings.name}');
          
          switch (settings.name) {
            case '/checkout':
              return MaterialPageRoute(
                builder: (context) => const CheckoutScreen(),
                settings: settings,
              );
            case '/admin':
              return MaterialPageRoute(
                builder: (context) => const AdminDashboardScreen(),
                settings: settings,
              );
            case '/home':
              return MaterialPageRoute(
                builder: (context) => const MainNavWidget(),
                settings: settings,
              );
            default:
              return null;
          }
        },
        // ✅ Thêm onUnknownRoute để handle fallback
        onUnknownRoute: (settings) {
          print('❌ Unknown route: ${settings.name}');
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Lỗi'),
                backgroundColor: Colors.red,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Không tìm thấy trang: ${settings.name}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home', 
                        (route) => false,
                      ),
                      child: const Text('Về trang chủ'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        print('🏠 Building AuthWrapper...');
        print('🔐 Auth state: isAuthenticated=${auth.isAuthenticated}, isAdmin=${auth.isAdmin}');
        
        if (auth.isAuthenticated && auth.isAdmin) {
          print('🚀 Authenticated Admin - showing AdminDashboard');
          return const AdminDashboardScreen();
        } else {
          print('🚀 Not authenticated admin - showing MainNavWidget');
          return const MainNavWidget();
        }
      },
    );
  }
}

