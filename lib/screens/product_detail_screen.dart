import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../utils/formatters.dart'; // Giả sử bạn có file này

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final bool isFavorite; // Giữ lại isFavorite và callback
  final int cartCount; // Số lượng hiện tại trong giỏ hàng (nếu cần hiển thị)
  final ValueChanged<bool> onFavoriteChanged;
  final ValueChanged<int>? onCartCountChanged; // <<--- THÊM DÒNG NÀY

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.cartCount,
    required this.onFavoriteChanged,
    this.onCartCountChanged, // <<--- THÊM DÒNG NÀY
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late bool _isFavoriteCurrent;
  late int _currentCartCount; // State cục bộ để quản lý số lượng trong trang chi tiết

  @override
  void initState() {
    super.initState();
    _isFavoriteCurrent = widget.isFavorite;
    _currentCartCount = widget.cartCount;
     // Lắng nghe thay đổi từ CartProvider để cập nhật _currentCartCount nếu cần
    // Hoặc bạn có thể lấy trực tiếp từ CartProvider trong build method
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    // Khởi tạo _currentCartCount từ provider nếu widget.cartCount không phải là nguồn chính xác nhất
    _currentCartCount = cartProvider.cartCounts[widget.product.id] ?? 0;
  }

  void _toggleFavorite() {
    setState(() {
      _isFavoriteCurrent = !_isFavoriteCurrent;
    });
    widget.onFavoriteChanged(_isFavoriteCurrent);
  }

  void _updateCartCount(int newCount) {
    if (mounted) {
      setState(() {
        _currentCartCount = newCount;
      });
    }
    widget.onCartCountChanged?.call(newCount); // Gọi callback nếu nó được cung cấp
  }


  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    // Cập nhật _currentCartCount từ provider mỗi khi build để đảm bảo đồng bộ
    // Điều này quan trọng nếu có thay đổi từ nguồn khác ngoài trang chi tiết
    final actualCartCountFromProvider = cartProvider.cartCounts[widget.product.id] ?? 0;
    if (_currentCartCount != actualCartCountFromProvider) {
      _currentCartCount = actualCartCountFromProvider;
    }


    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg', // Đảm bảo bạn có ảnh này
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill( // Thêm lớp phủ mờ để chữ dễ đọc hơn
            child: Container(
              color: Colors.black.withOpacity(0.45),
            ),
          ),
          SafeArea(
            child: Column( // Sử dụng Column thay vì Center + SingleChildScrollView để AppBar ở trên cùng
              children: [
                // AppBar tuỳ chỉnh
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                        splashRadius: 24,
                      ),
                      Expanded(
                        child: Text(
                          widget.product.name ?? 'Chi tiết sản phẩm',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22, // Điều chỉnh kích thước
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center, // Căn giữa tiêu đề
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isFavoriteCurrent ? Icons.favorite : Icons.favorite_border,
                          color: _isFavoriteCurrent ? Colors.redAccent : Colors.white,
                          size: 28,
                        ),
                        onPressed: _toggleFavorite,
                        splashRadius: 24,
                      ),
                    ],
                  ),
                ),
                Expanded( // Cho phép nội dung cuộn nếu vượt quá màn hình
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), // Điều chỉnh padding top
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Ảnh sản phẩm
                          Hero( // Thêm Hero animation cho ảnh
                            tag: 'product-image-${widget.product.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24), // Bo tròn hơn
                              child: CachedNetworkImage(
                                imageUrl: widget.product.imageUrl ?? 'https://via.placeholder.com/300',
                                height: MediaQuery.of(context).size.width * 0.65, // Kích thước ảnh theo chiều rộng màn hình
                                width: MediaQuery.of(context).size.width * 0.65,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const Center(child: CircularProgressIndicator(color: Colors.orangeAccent,)),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.broken_image, size: 100, color: Colors.white30),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Tên sản phẩm (có thể lặp lại nếu AppBar không đủ)
                          Text(
                            widget.product.name ?? 'N/A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          // Giá tiền
                          Text(
                            formatCurrency(widget.product.price), // Sử dụng hàm từ utils
                            style: const TextStyle(
                              color: Colors.white, // <<--- THAY ĐỔI Ở ĐÂY: GIÁ MÀU TRẮNG
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Mô tả
                          Text(
                            widget.product.description ?? 'Không có mô tả.',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16, // Kích thước chữ mô tả
                              height: 1.5, // Giãn dòng
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // Nút tăng/giảm số lượng
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30)
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min, // Thu gọn Row
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.white70, size: 30),
                                  onPressed: _currentCartCount > 0
                                      ? () {
                                          if (widget.product.id != null) {
                                            cartProvider.removeFromCart(widget.product.id!);
                                            _updateCartCount(cartProvider.cartCounts[widget.product.id] ?? 0);
                                          }
                                        }
                                      : null,
                                  splashRadius: 24,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    '$_currentCartCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.white70, size: 30),
                                  onPressed: () {
                                     if (widget.product.id != null) {
                                        cartProvider.addToCart(widget.product.id!);
                                        _updateCartCount(cartProvider.cartCounts[widget.product.id] ?? 0);
                                      }
                                  },
                                  splashRadius: 24,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Nút thêm vào giỏ hàng
                          OutlinedButton.icon( // <<--- THAY ĐỔI Ở ĐÂY: SỬ DỤNG OUTLINEDBUTTON
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white, // Chữ và icon màu trắng
                              side: BorderSide(color: Colors.white.withOpacity(0.8), width: 1.5), // Viền trắng, hơi mờ
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              if (widget.product.id != null) {
                                cartProvider.addToCart(widget.product.id!);
                                _updateCartCount(cartProvider.cartCounts[widget.product.id] ?? 0); // Cập nhật số lượng ngay
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${widget.product.name ?? 'Sản phẩm'} đã được thêm vào giỏ!'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.add_shopping_cart_outlined), // Icon outline cho đồng bộ
                            label: const Text('Thêm vào giỏ hàng'),
                          ),
                           const SizedBox(height: 20), // Thêm khoảng trống ở cuối
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}