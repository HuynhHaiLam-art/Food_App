import 'dart:async'; // For Timer (debouncing search)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Models
import 'package:food_app/models/product.dart';

// Providers
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/providers/auth_provider.dart'; // <<--- THÊM DÒNG NÀY

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
  int _currentTab = 0; // 0: Home, 1: Favorites, 2: Cart (nav), 3: Profile (nav)

  final Set<int> _favoriteIds = {}; // Sẽ được cải thiện sau (ví dụ: FavoriteProvider)
  String _searchKeyword = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Bỏ các biến state cục bộ cho auth, sẽ dùng AuthProvider
  // bool _isLoggedIn = false;
  // int? _userId;
  // String _userName = '';
  // String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    // Không cần gọi tryAutoLogin ở đây nữa nếu MyApp hoặc một widget cha đã xử lý
    // Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();
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

  List<Product> _getFilteredProducts() {
    if (_allProducts.isEmpty) return [];

    final isFavoriteTab = _currentTab == 1;
    final selectedCatId = categoryIds[_selectedCategoryIndex];

    return _allProducts.where((p) {
      final matchesCategory = isFavoriteTab
          ? _favoriteIds.contains(p.id) // Chỉ hiển thị mục yêu thích nếu ở tab Yêu thích
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
    final authProvider = Provider.of<AuthProvider>(context); // Lấy AuthProvider
    final filteredProducts = _getFilteredProducts();

    // Widget cho nội dung chính (Home hoặc Favorites)
    Widget currentScreenContent;
    if (_currentTab == 0 || _currentTab == 1) { // Home hoặc Favorites
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
          if (_currentTab == 0) // Chỉ hiển thị category selector ở tab Home
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
                               : 'Không tìm thấy sản phẩm phù hợp.'
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
                    final isFavorite = _favoriteIds.contains(p.id);
                    final cartCount = cartProvider.cartCounts[p.id] ?? 0;

                    return GestureDetector(
                      onTap: () async {
                        // final result = // Không cần result nữa nếu onFavoriteChanged đã đủ
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              product: p,
                              isFavorite: isFavorite,
                              cartCount: cartCount,
                              onFavoriteChanged: (fav) {
                                if (mounted) {
                                  setState(() {
                                    if (fav) {
                                      if (p.id != null) _favoriteIds.add(p.id!);
                                    } else {
                                      _favoriteIds.remove(p.id);
                                    }
                                  });
                                }
                              },
                              onCartCountChanged: (newCount) {
                                if (mounted) {
                                  setState(() {}); // Rebuild để cập nhật cartCount trên ProductCard nếu cần
                                }
                              },
                            ),
                          ),
                        );
                        // Cập nhật lại UI sau khi quay lại từ ProductDetailScreen
                        // để đảm bảo trạng thái favorite và cartCount là mới nhất
                        if (mounted) setState(() {});
                      },
                      child: ProductCard(
                        product: p,
                        isFavorite: isFavorite,
                        cartCount: cartCount,
                        onFavorite: () {
                          if (mounted) {
                            setState(() {
                              if (isFavorite) {
                                _favoriteIds.remove(p.id);
                              } else {
                                if (p.id != null) _favoriteIds.add(p.id!);
                              }
                            });
                          }
                        },
                        onAdd: () {
                          if (p.id != null) {
                            cartProvider.addToCart(p.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã thêm ${p.name} vào giỏ hàng!'),
                                duration: const Duration(milliseconds: 900),
                                backgroundColor: Colors.green[700],
                              ),
                            );
                          }
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
    } else {
      // Các tab khác (Cart, Profile) sẽ được xử lý bằng cách điều hướng
      // hoặc hiển thị một widget trống nếu không muốn giữ state của tab Home/Favorites
      currentScreenContent = const Center(child: Text("Đang chuyển hướng...", style: TextStyle(color: Colors.white)));
    }


    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: currentScreenContent, // Hiển thị nội dung tab hiện tại
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        // Chỉ có 2 màu cho 2 tab mà HomeScreen quản lý trực tiếp (Home, Favorites)
        // Tab "Trang chủ" sẽ là màu trắng khi được chọn.
        // Tab "Yêu thích" vẫn giữ màu hồng hoặc bạn có thể đổi thành Colors.white nếu muốn.
        selectedItemColor: _currentTab == 0 ? Colors.white : Colors.pinkAccent,
        unselectedItemColor: Colors.white60,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        iconSize: 28,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'Yêu thích',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_rounded),
                if (cartProvider.totalItems > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: Colors.redAccent,
                      child: Text(
                        '${cartProvider.totalItems}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Giỏ hàng',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Cá nhân',
          ),
        ],
        // currentIndex chỉ cần là _currentTab vì nó chỉ là 0 hoặc 1
        currentIndex: _currentTab,
        onTap: (index) async {
          if (index == 2) { // Tab Giỏ hàng
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CartScreen(products: _allProducts),
              ),
            );
            // _currentTab không thay đổi
          } else if (index == 3) { // Tab Cá nhân
            if (authProvider.isAuthenticated) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            } else {
              final loggedInSuccessfully = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
              if (loggedInSuccessfully == true && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              }
            }
            // _currentTab không thay đổi
          } else { // Tab Home hoặc Favorites (index 0 hoặc 1)
            if (mounted) {
              setState(() {
                _currentTab = index;
              });
            }
          }
        },
      ),
    );
  }

  // Bỏ _navigateToProfile vì ProfileScreen giờ tự lấy user từ AuthProvider
  // Future<void> _navigateToProfile() async { ... }
}