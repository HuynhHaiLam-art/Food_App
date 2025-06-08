import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/formatters.dart';
// import './checkout_screen.dart'; // TODO: Tạo và import màn hình Checkout
// import './login_screen.dart'; // TODO: Import màn hình Login nếu cần điều hướng

class CartScreen extends StatelessWidget {
  final List<Product> products; // Danh sách tất cả sản phẩm để lấy chi tiết

  const CartScreen({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartCounts = cartProvider.cartCounts;
    final theme = Theme.of(context); // Lấy theme hiện tại

    // Lọc và tạo danh sách chi tiết các sản phẩm trong giỏ hàng
    final cartItemsDetail = products.where((p) {
      return p.id != null && cartCounts.containsKey(p.id);
    }).map((p) {
      return {
        'product': p,
        'quantity': cartCounts[p.id!]!,
      };
    }).toList();

    // Tính tổng giá trị giỏ hàng
    final totalPrice = cartItemsDetail.fold<int>(
      0,
      (sum, item) => sum + ((item['product'] as Product).price ?? 0) * (item['quantity'] as int),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/background.jpg', // Đảm bảo bạn có ảnh này trong assets
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.6), // Lớp phủ tối hơn một chút
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Giỏ hàng', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: cartItemsDetail.isEmpty
              ? const Center( // <<--- PHẦN GIỎ HÀNG TRỐNG
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.white), // <<--- THAY ĐỔI Ở ĐÂY
                      SizedBox(height: 16),
                      Text(
                        'Giỏ hàng của bạn đang trống',
                        style: TextStyle(color: Colors.white, fontSize: 16), // <<--- THAY ĐỔI Ở ĐÂY
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: cartItemsDetail.length,
                        itemBuilder: (context, index) {
                          final item = cartItemsDetail[index];
                          final product = item['product'] as Product;
                          final quantity = item['quantity'] as int;
                          final imageUrl = (product.imageUrl?.isNotEmpty ?? false)
                              ? product.imageUrl!
                              : 'https://via.placeholder.com/80';


                          return Card(
                            color: Colors.white.withOpacity(0.15),
                            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Center(child: CircularProgressIndicator(strokeWidth: 2.0, color: theme.colorScheme.primary,)),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.broken_image, color: Colors.white54, size: 40),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name ?? 'N/A',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatCurrency(product.price),
                                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column( // <<--- PHẦN ĐIỀU KHIỂN SỐ LƯỢNG
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 28),
                                            onPressed: () {
                                              if (product.id != null) {
                                                cartProvider.removeFromCart(product.id!);
                                              }
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                            child: Text(
                                              '$quantity',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28), // <<--- THAY ĐỔI Ở ĐÂY
                                            onPressed: () {
                                              if (product.id != null) {
                                                cartProvider.addToCart(product.id!);
                                              }
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        formatCurrency((product.price ?? 0) * quantity),
                                        style: const TextStyle( // <<--- THAY ĐỔI Ở ĐÂY
                                            color: Colors.white, // Đổi thành màu trắng
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Phần tổng kết và nút đặt hàng
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tổng cộng:', // Đã sửa từ 'Total:' thành 'Tổng cộng:' cho nhất quán
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                formatCurrency(totalPrice),
                                style: const TextStyle( // <<--- THAY ĐỔI Ở ĐÂY
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, // Đổi thành màu trắng
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton( // <<--- THAY ĐỔI Ở ĐÂY: SỬ DỤNG OUTLINEDBUTTON
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white, // Chữ màu trắng
                                side: BorderSide(color: Colors.white.withOpacity(0.8), width: 1.5), // Viền trắng, hơi mờ
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              onPressed: cartItemsDetail.isEmpty
                                  ? null
                                  : () {
                                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                      if (authProvider.isAuthenticated) {
                                        // TODO: Điều hướng đến CheckoutScreen
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Đã đăng nhập. Đang chuyển đến thanh toán...')),
                                        );
                                      } else {
                                        // TODO: Điều hướng đến LoginScreen
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Vui lòng đăng nhập để đặt hàng.')),
                                        );
                                      }
                                    },
                              child: const Text('Đặt Hàng'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}