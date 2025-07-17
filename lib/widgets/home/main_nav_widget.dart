import 'package:flutter/material.dart';
import 'package:food_app/screens/home_screen.dart';
import 'package:food_app/screens/cart_screen.dart';
import 'package:food_app/screens/profile_screen.dart';
import 'package:food_app/screens/favorite_screen.dart';
import 'package:food_app/screens/login_screen.dart' as auth;
import 'package:provider/provider.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/providers/favorite_provider.dart';
import 'package:food_app/providers/auth_provider.dart';
import 'package:food_app/themes/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // Thêm dòng này

class MainNavWidget extends StatefulWidget {
  final int initialTab;
  const MainNavWidget({super.key, this.initialTab = 0});

  @override
  State<MainNavWidget> createState() => _MainNavWidgetState();
}

class _MainNavWidgetState extends State<MainNavWidget>
    with TickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _animationController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    // ✅ Khởi tạo controllers trong initState
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pageController = PageController(initialPage: widget.initialTab);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose(); // ✅ Dispose đúng cách
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });

      // ✅ Kiểm tra _pageController đã được khởi tạo
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }

      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  Widget _getCurrentScreen(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const FavoriteScreen();
      case 2:
        return const CartScreen();
      case 3:
        return authProvider.isAuthenticated
            ? const ProfileScreen()
            : const auth.LoginScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<CartProvider, FavoriteProvider, AuthProvider>(
      builder: (context, cartProvider, favoriteProvider, authProvider, _) {
        int cartCount = cartProvider.cartCounts.values.fold(0, (a, b) => a + b);
        int favoriteCount = favoriteProvider.favoriteProductIds.length;

        return Scaffold(
          body: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            itemCount: 4,
            itemBuilder: (context, index) => _getCurrentScreen(index),
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1A1A2E),
                        Color(0xFF16213E),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    onTap: _onTabTapped,
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    selectedItemColor: AppTheme.primaryOrange,
                    unselectedItemColor: Colors.white54,
                    selectedLabelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                    items: [
                      _buildNavItem(
                        icon: Icons.home_rounded,
                        label: 'Trang chủ',
                        index: 0,
                      ),
                      _buildNavItem(
                        icon: Icons.favorite_rounded,
                        label: 'Yêu thích',
                        index: 1,
                        badge: favoriteCount,
                        badgeColor: Colors.red,
                      ),
                      _buildNavItem(
                        icon: Icons.shopping_cart_rounded,
                        label: 'Giỏ hàng',
                        index: 2,
                        badge: cartCount,
                        badgeColor: AppTheme.primaryOrange,
                      ),
                      _buildNavItem(
                        icon: authProvider.isAuthenticated
                            ? Icons.person_rounded
                            : Icons.login_rounded,
                        label: authProvider.isAuthenticated ? 'Cá nhân' : 'Đăng nhập',
                        index: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    int badge = 0,
    Color? badgeColor,
  }) {
    final isSelected = _selectedIndex == index;

    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryOrange.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _buildIconWithBadge(
          icon,
          badge,
          badgeColor ?? AppTheme.primaryOrange,
          size: isSelected ? 26 : 24,
        ),
      ),
      label: label,
    );
  }

  Widget _buildIconWithBadge(
    IconData icon,
    int count,
    Color badgeColor, {
    double size = 24,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: size),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [badgeColor, badgeColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 18,
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}