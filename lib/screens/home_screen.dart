import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Models
import 'package:food_app/models/product.dart';

// Providers
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/providers/auth_provider.dart';
import 'package:food_app/providers/favorite_provider.dart';

// Screens
import 'package:food_app/screens/product_detail_screen.dart';
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
    final authProvider = Provider.of<AuthProvider>(context);
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
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 16, bottom: 4, right: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          tooltip: 'Thông tin King Burger',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                              ),
                              builder: (context) {
                                return Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: [
                                      const Text(
                                        'King Burger',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ListTile(
                                        leading: const Icon(Icons.location_on, color: Colors.deepOrange),
                                        title: const Text(
                                          'Địa chỉ: 2 Hải Triều, Bến Nghé, Quận 1, TP.HCM',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        onTap: () async {
                                          const googleMapsUrl =
                                              'https://www.google.com/maps/search/?api=1&query=Burger+King+Bitexco,2+Hải+Triều,Bến+Nghé,Quận+1,TP.HCM';
                                          if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
                                            await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Không mở được Google Maps!')),
                                            );
                                          }
                                        },
                                      ),
                                      const ListTile(
                                        leading: Icon(Icons.phone, color: Colors.green),
                                        title: Text(
                                          'Số điện thoại: 0123 456 789',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.card_giftcard, color: Colors.purple),
                                        title: const Text(
                                          'Thẻ quà tặng: Nhận ưu đãi hấp dẫn khi mua thẻ!',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text('Ưu đãi & Quà tặng'),
                                              content: const Text(
                                                '• Tặng voucher 50k cho đơn đầu tiên.\n'
                                                '• Tích điểm đổi quà hấp dẫn.\n'
                                                '• Nhận ưu đãi sinh nhật, lễ tết, thành viên VIP.\n'
                                                '• Thẻ quà tặng áp dụng toàn hệ thống King Burger.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Đóng'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.fastfood, color: Colors.brown),
                                        title: const Text(
                                          'Thông tin về đồ ăn: Burger, Pasta, Salad...',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text('Thông tin về đồ ăn'),
                                              content: const Text(
                                                '• Nguyên liệu nhập khẩu, kiểm định an toàn thực phẩm.\n'
                                                '• Quy trình chế biến khép kín, đảm bảo vệ sinh.\n'
                                                '• Đóng gói bằng vật liệu thân thiện môi trường.\n'
                                                '• Giao hàng nhanh, giữ nhiệt tốt.\n'
                                                '• Đa dạng món: Burger bò Mỹ, Pasta Ý, Salad hữu cơ, v.v.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Đóng'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const ListTile(
                                        leading: Icon(Icons.room_service, color: Colors.blue),
                                        title: Text(
                                          'Dịch vụ: Giao hàng tận nơi, đặt tiệc, combo gia đình...',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.policy, color: Colors.teal),
                                        title: const Text(
                                          'Chính sách: Đổi trả trong 1h, hoàn tiền nếu không hài lòng.',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text('Chính sách'),
                                              content: const Text(
                                                '• Đổi trả miễn phí trong 1 giờ nếu sản phẩm lỗi/hỏng.\n'
                                                '• Hoàn tiền 100% nếu không hài lòng về chất lượng.\n'
                                                '• Hỗ trợ đổi món nếu đặt nhầm trong 10 phút.\n'
                                                '• Chính sách bảo mật thông tin khách hàng nghiêm ngặt.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Đóng'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const ListTile(
                                        leading: Icon(Icons.delivery_dining, color: Colors.red),
                                        title: Text(
                                          'Giao hàng: Miễn phí nội thành cho đơn từ 150k.',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.support_agent, color: Colors.indigo),
                                        title: const Text(
                                          'Hỗ trợ: 24/7 qua hotline và chat trực tuyến.',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.white,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                                            ),
                                            builder: (_) => const _ChatBotSheet(),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.public, color: Colors.blueAccent),
                                        title: const Text(
                                          'Social Media',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            backgroundColor: Colors.white,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                                            ),
                                            builder: (_) => Padding(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    'Burger King Social Bio',
                                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(height: 18),
                                                  ListTile(
                                                    leading: const Icon(Icons.facebook, color: Colors.blue),
                                                    title: const Text('Facebook'),
                                                    onTap: () async {
                                                      const url = 'https://www.facebook.com/burgerking';
                                                      if (await canLaunchUrl(Uri.parse(url))) {
                                                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                                      }
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(Icons.camera_alt, color: Colors.purple),
                                                    title: const Text('Instagram'),
                                                    onTap: () async {
                                                      const url = 'https://www.instagram.com/burgerking.vn/';
                                                      if (await canLaunchUrl(Uri.parse(url))) {
                                                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                                      }
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(Icons.ondemand_video, color: Colors.red),
                                                    title: const Text('YouTube'),
                                                    onTap: () async {
                                                      const url = 'https://www.youtube.com/@BURGERKING';
                                                      if (await canLaunchUrl(Uri.parse(url))) {
                                                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                                      }
                                                    },
                                                  ),
                                                  const SizedBox(height: 8),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Đóng'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        if (authProvider.isAuthenticated && authProvider.currentUser != null)
                          Text(
                            'Xin chào, ${authProvider.currentUser!.name ?? ''} 👋',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
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

// SMART CHATBOT
class _ChatBotSheet extends StatefulWidget {
  const _ChatBotSheet();

  @override
  State<_ChatBotSheet> createState() => _ChatBotSheetState();
}

class _ChatBotSheetState extends State<_ChatBotSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(isBot: true, text: 'Chào bạn! Tôi là KingBot, hỗ trợ 24/7. Hãy gửi câu hỏi về thực đơn, ưu đãi, đặt hàng, chính sách, hoặc góp ý cho cửa hàng nhé!')
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(isBot: false, text: text.trim()));
    });
    await Future.delayed(const Duration(milliseconds: 300));

    final lower = text.toLowerCase();

    String reply;
    if (lower.contains('giờ mở cửa') || lower.contains('giờ đóng cửa')) {
      reply = 'King Burger mở cửa từ 8:00 sáng đến 10:00 tối mỗi ngày bạn nhé!';
    } else if (lower.contains('địa chỉ') || lower.contains('ở đâu')) {
      reply = 'King Burger địa chỉ: 2 Hải Triều, Bến Nghé, Quận 1, TP.HCM. Bạn có muốn chỉ đường trên Google Maps không?';
    } else if (lower.contains('menu') || lower.contains('thực đơn') || lower.contains('món')) {
      reply = 'Thực đơn nổi bật gồm: Burger bò Mỹ, Pasta Ý, Salad hữu cơ, gà rán, khoai tây chiên và nhiều món khác. Bạn muốn xem chi tiết món nào?';
    } else if (lower.contains('ưu đãi') || lower.contains('khuyến mãi') || lower.contains('voucher')) {
      reply = 'Hiện tại có ưu đãi: Tặng voucher 50k cho đơn đầu tiên, miễn phí giao hàng nội thành từ 150k, tích điểm đổi quà và ưu đãi sinh nhật!';
    } else if (lower.contains('giao hàng') || lower.contains('ship') || lower.contains('delivery')) {
      reply = 'King Burger giao hàng tận nơi nội thành, miễn phí cho đơn từ 150k. Bạn muốn đặt món nào?';
    } else if (lower.contains('hotline') || lower.contains('số điện thoại')) {
      reply = 'Hotline hỗ trợ: 0123 456 789. Bạn có thể gọi bất cứ khi nào cần!';
    } else if (lower.contains('chính sách') || lower.contains('đổi trả') || lower.contains('hoàn tiền')) {
      reply = 'Chính sách: Đổi trả miễn phí trong 1h nếu sản phẩm lỗi, hoàn tiền nếu không hài lòng, bảo mật thông tin khách hàng.';
    } else if (lower.contains('facebook') || lower.contains('fanpage')) {
      reply = 'Fanpage Facebook: https://www.facebook.com/burgerking';
    } else if (lower.contains('instagram')) {
      reply = 'Instagram: https://www.instagram.com/burgerking.vn/';
    } else if (lower.contains('youtube')) {
      reply = 'YouTube: https://www.youtube.com/@BURGERKING';
    } else if (lower.contains('cảm ơn') || lower.contains('thanks')) {
      reply = 'Cảm ơn bạn đã liên hệ King Burger! Nếu cần thêm thông tin, bạn cứ hỏi nhé!';
    } else if (lower.contains('tên bạn') || lower.contains('bạn là ai')) {
      reply = 'Tôi là KingBot - trợ lý ảo thông minh của King Burger, luôn sẵn sàng hỗ trợ bạn!';
    } else if (lower.contains('giá') || lower.contains('bao nhiêu')) {
      reply = 'Bạn muốn hỏi giá món nào? Vui lòng nhập tên món để mình tra cứu giúp bạn nhé!';
    } else if (lower.contains('order') || lower.contains('đặt món') || lower.contains('mua')) {
      reply = 'Bạn muốn đặt món gì? Hãy nhắn tên món và số lượng, KingBot sẽ hỗ trợ bạn!';
    } else if (lower.contains('thanh toán') || lower.contains('payment')) {
      reply = 'King Burger chấp nhận thanh toán tiền mặt, thẻ ngân hàng, ví Momo, ZaloPay và chuyển khoản nhé!';
    } else {
      reply = 'KingBot xin lỗi, mình chưa hiểu ý bạn. Bạn có thể hỏi về menu, ưu đãi, địa chỉ, giao hàng, chính sách, hoặc liên hệ hotline nhé!';
    }

    setState(() {
      _messages.add(_ChatMessage(isBot: true, text: reply));
    });

    await Future.delayed(const Duration(milliseconds: 200));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SizedBox(
          height: 420,
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'King Burger Chatbot',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final m = _messages[index];
                    final align = m.isBot ? Alignment.centerLeft : Alignment.centerRight;
                    final color = m.isBot ? const Color.fromARGB(255, 155, 151, 151) : Colors.orange[100];
                    return Container(
                      alignment: align,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(m.text, style: const TextStyle(fontSize: 15)),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: 'Nhập nội dung cần hỏi...',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (v) {
                        _sendMessage(v);
                        _controller.clear();
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.orange, size: 28),
                    onPressed: () {
                      _sendMessage(_controller.text);
                      _controller.clear();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final bool isBot;
  final String text;
  _ChatMessage({required this.isBot, required this.text});
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