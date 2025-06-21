import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';
import '../utils/formatters.dart';
import '../widgets/home/background_widget.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final productId = widget.product.id;
    final cartCount = productId != null ? (cartProvider.cartCounts[productId] ?? 0) : 0;
    final isFavorite = productId != null ? favoriteProvider.isFavorite(productId) : false;

    void toggleFavorite() {
      if (productId != null) {
        favoriteProvider.toggleFavorite(productId);
      }
    }

    void addToCart() {
      if (productId != null) {
        cartProvider.addToCart(widget.product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.name ?? 'Sản phẩm'} đã được thêm vào giỏ!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {});
      }
    }

    void removeFromCart() {
      if (productId != null && cartCount > 0) {
        cartProvider.removeFromCart(productId);
        setState(() {});
      }
    }

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
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
                          fontSize: 22,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.redAccent : Colors.white,
                        size: 28,
                      ),
                      onPressed: toggleFavorite,
                      splashRadius: 24,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Ảnh sản phẩm
                        Hero(
                          tag: 'product-image-${widget.product.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: CachedNetworkImage(
                              imageUrl: widget.product.imageUrl ?? 'https://via.placeholder.com/300',
                              height: MediaQuery.of(context).size.width * 0.65,
                              width: MediaQuery.of(context).size.width * 0.65,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.broken_image, size: 100, color: Colors.white30),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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
                        Text(
                          formatCurrency(widget.product.price),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.product.description ?? 'Không có mô tả.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Nút tăng/giảm số lượng
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.white70, size: 30),
                                onPressed: cartCount > 0 ? removeFromCart : null,
                                splashRadius: 24,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  '$cartCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.white70, size: 30),
                                onPressed: addToCart,
                                splashRadius: 24,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.8), width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          onPressed: addToCart,
                          icon: const Icon(Icons.add_shopping_cart_outlined),
                          label: const Text('Thêm vào giỏ hàng'),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}