import 'package:flutter/material.dart';
import 'package:food_app/screens/home_screen.dart';
import 'package:food_app/screens/cart_screen.dart';
import 'package:food_app/screens/profile_screen.dart';
import 'package:food_app/screens/favorite_screen.dart';
import 'package:provider/provider.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/providers/favorite_provider.dart';

class MainNavWidget extends StatefulWidget {
  final int initialTab;
  const MainNavWidget({super.key, this.initialTab = 0});

  @override
  State<MainNavWidget> createState() => _MainNavWidgetState();
}

class _MainNavWidgetState extends State<MainNavWidget> {
  late int _selectedIndex;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _screens = const [
      HomeScreen(),
      FavoriteScreen(),
      CartScreen(),
      ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final favoriteProvider = Provider.of<FavoriteProvider>(context);

    int cartCount = cartProvider.cartCounts.values.fold(0, (a, b) => a + b);
    int favoriteCount = favoriteProvider.favoriteProductIds.length;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.favorite),
                if (favoriteCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 16,
                      ),
                      child: Text(
                        favoriteCount > 99 ? '99+' : '$favoriteCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Yêu thích',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart),
                if (cartCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 16,
                      ),
                      child: Text(
                        cartCount > 99 ? '99+' : '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Giỏ hàng',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}