import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Models
import 'package:food_app/models/product.dart';

// Providers
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/providers/auth_provider.dart';
import 'package:food_app/providers/product_provider.dart';
import 'package:food_app/providers/favorite_provider.dart';

// Screens
import 'package:food_app/screens/product_detail_screen.dart';
import 'package:food_app/screens/cart_screen.dart';
import 'package:food_app/screens/login_screen.dart';
import 'package:food_app/screens/profile_screen.dart';

// Services
import 'package:food_app/services/product_api_service.dart';

// Widgets
import 'package:food_app/widgets/home/banner_widget.dart';
import 'package:food_app/widgets/home/search_bar_widget.dart';
import 'package:food_app/widgets/home/category_selector_widget.dart';
import 'package:food_app/widgets/home/product_card_widget.dart';
import 'package:food_app/widgets/home/empty_state_widget.dart';
import 'package:food_app/widgets/home/background_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> _futureProducts;
  List<Product> _allProducts = [];

  final List<String> categories = ['All', 'Burger', 'Pasta', 'Salad'];
  final List<int?> categoryIds = [null, 2, 3, 4];
  int _selectedCategoryIndex = 0;
  int _currentTab = 0; // 0: Home, 1: Favorites, 2: Cart, 3: Profile

  String _searchKeyword = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    _futureProducts = ProductApiService().fetchProducts();
    _futureProducts.then((products) {
      if (mounted) {
        setState(() {
          _allProducts = products;
        });
        Provider.of<ProductProvider>(context, listen: false).setProducts(products);
      }
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải sản phẩm: $error')),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _searchKeyword = query.trim().toLowerCase();
        });
      }
    });
  }

  List<Product> _getFilteredProducts(Set<int> favoriteIds) {
    if (_allProducts.isEmpty) return [];

    final isFavoriteTab = _currentTab == 1;
    final selectedCatId = categoryIds[_selectedCategoryIndex];

    return _allProducts.where((p) {
      final matchesCategory = isFavoriteTab
          ? favoriteIds.contains(p.id)
          : (selectedCatId == null || p.categoryId == selectedCatId);

      final matchesSearch = _searchKeyword.isEmpty ||
          (p.name?.toLowerCase().contains(_searchKeyword) ?? false) ||
          (p.description?.toLowerCase().contains(_searchKeyword) ?? false);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final favoriteIds = favoriteProvider.favoriteProductIds.toSet();
    final filteredProducts = _getFilteredProducts(favoriteIds);

    Widget currentScreenContent;
    if (_currentTab == 0 || _currentTab == 1) {
      // Home hoặc Yêu thích
      currentScreenContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BannerWidget(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBarWidget(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onClear: () {
                _searchController.clear();
                if (mounted) {
                  setState(() {
                    _searchKeyword = '';
                  });
                }
                _debounce?.cancel();
              },
            ),
          ),
          if (_currentTab == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: CategorySelector(
                categories: categories,
                selectedCategoryIndex: _selectedCategoryIndex,
                onCategorySelected: (index) {
                  if (mounted) {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  }
                },
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _futureProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _allProducts.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                } else if (snapshot.hasError && _allProducts.isEmpty) {
                  return EmptyStateWidget(
                    message: 'Lỗi tải dữ liệu: ${snapshot.error}',
                    icon: Icons.error_outline,
                  );
                }
                if (filteredProducts.isEmpty && _allProducts.isNotEmpty) {
                  return EmptyStateWidget(
                    message: _currentTab == 1
                        ? 'Chưa có sản phẩm yêu thích nào.'
                        : 'Không tìm thấy sản phẩm phù hợp.',
                  );
                }
                if (_allProducts.isEmpty && !snapshot.hasError && snapshot.connectionState != ConnectionState.waiting) {
                  return const EmptyStateWidget(message: 'Chưa có sản phẩm nào.');
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: MediaQuery.of(context).size.width < 600 ? 200 : 350,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: MediaQuery.of(context).size.width < 600 ? 0.65 : 0.75,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final p = filteredProducts[index];
                    final isFavorite = favoriteIds.contains(p.id);
                    final cartCount = cartProvider.cartCounts[p.id] ?? 0;

                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              product: p,
                            ),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                      child: ProductCard(
                        product: p,
                        isFavorite: isFavorite,
                        cartCount: cartCount,
                        onFavorite: () {
                          if (p.id != null) {
                            favoriteProvider.toggleFavorite(p.id!);
                          }
                        },
                        onAdd: () {
                          cartProvider.addToCart(p);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã thêm ${p.name} vào giỏ hàng!'),
                              duration: const Duration(milliseconds: 900),
                              backgroundColor: Colors.green[700],
                            ),
                          );
                        },
                        onRemove: cartCount > 0
                            ? () {
                                if (p.id != null) {
                                  cartProvider.removeFromCart(p.id!);
                                }
                              }
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    } else if (_currentTab == 2) {
      // Tab Giỏ hàng
      currentScreenContent = const CartScreen();
    } else if (_currentTab == 3) {
      // Tab Cá nhân
      currentScreenContent = authProvider.isAuthenticated
          ? const ProfileScreen()
          : const LoginScreen();
    } else {
      currentScreenContent = const Center(child: Text("Đang chuyển hướng...", style: TextStyle(color: Colors.white)));
    }

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: currentScreenContent,
            ),
          ),
        ),
        // Thêm bottomNavigationBar nếu cần
      ),
    );
  }
}