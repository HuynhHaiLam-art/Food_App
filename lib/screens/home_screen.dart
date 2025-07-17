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
import 'package:food_app/screens/register_screen.dart';

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

    final selectedCatId = categoryIds[_selectedCategoryIndex];

    return _allProducts.where((p) {
      final matchesCategory = selectedCatId == null || p.categoryId == selectedCatId;
      
      final matchesSearch = _searchKeyword.isEmpty ||
          (p.name?.toLowerCase().contains(_searchKeyword) ?? false) ||
          (p.description?.toLowerCase().contains(_searchKeyword) ?? false);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final favoriteIds = favoriteProvider.favoriteProductIds.toSet();
    final filteredProducts = _getFilteredProducts(favoriteIds);

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
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
                          return const EmptyStateWidget(
                            message: 'Không tìm thấy sản phẩm phù hợp.',
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
                                    builder: (_) => ProductDetailScreen(product: p),
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
                                        cartProvider.removeFromCart(p);
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      if (success) {
        // Navigation được handle trong main.dart
        print('✅ Login successful - navigation handled by main.dart');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Đăng nhập thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Đăng nhập'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Logo/Title
                    Icon(
                      Icons.fastfood,
                      size: 80,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'King Burger',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!value.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isObscured,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _isObscured = !_isObscured;
                            });
                          },
                        ),
                      ),
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
                    const SizedBox(height: 32),

                    // Login button
                    ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _login,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Đăng nhập'),
                    ),
                    const SizedBox(height: 16),

                    // Test Admin Login Button
                    ElevatedButton(
                      onPressed: authProvider.isLoading ? null : () async {
                        _emailController.text = 'admin@gmail.com';
                        _passwordController.text = 'admin123';
                        await _login();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                      child: const Text('🚀 Test Admin Login'),
                    ),
                    const SizedBox(height: 24),

                    // Register link
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text('Chưa có tài khoản? Đăng ký ngay'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}