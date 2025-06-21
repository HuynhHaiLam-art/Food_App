import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_app/models/product.dart';
import 'package:food_app/utils/formatters.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final int cartCount;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;
  final VoidCallback? onRemove; // Có thể null nếu cartCount = 0

  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.cartCount,
    required this.onFavorite,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        splashColor: Colors.orange.withOpacity(0.08),
        highlightColor: Colors.orange.withOpacity(0.04),
        onTap: null, // Để có hiệu ứng splash khi tap vào card
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hình ảnh sản phẩm
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl ?? 'https://via.placeholder.com/300x200.png?text=No+Image',
                  height: MediaQuery.of(context).size.width < 600 ? 120 : 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white54),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.fastfood, size: 80, color: Colors.white24),
                ),
              ),
              const SizedBox(height: 10),

              // Tên sản phẩm
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  product.name ?? 'N/A',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),

              // Mô tả ngắn (nếu có)
              if (product.description != null && product.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                  child: Text(
                    product.description!,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),

              const Spacer(),

              // Giá, nút yêu thích và nút thêm/bớt giỏ hàng
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Nút yêu thích
                    Material(
                      color: Colors.white.withOpacity(0.1),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.redAccent : Colors.white,
                        ),
                        onPressed: onFavorite,
                        iconSize: 20,
                        splashRadius: 20,
                        tooltip: isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
                      ),
                    ),

                    // Giá sản phẩm
                    Expanded(
                      child: Center(
                        child: Text(
                          formatCurrency(product.price),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),

                    // Nút thêm/bớt giỏ hàng
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (cartCount > 0 && onRemove != null)
                          Material(
                            color: Colors.white.withOpacity(0.1),
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(Icons.remove, color: Colors.white),
                              onPressed: onRemove,
                              iconSize: 20,
                              splashRadius: 20,
                              tooltip: 'Bớt khỏi giỏ',
                            ),
                          ),
                        if (cartCount > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '$cartCount',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        Material(
                          color: Colors.white.withOpacity(0.1),
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: onAdd,
                            iconSize: 20,
                            splashRadius: 20,
                            tooltip: 'Thêm vào giỏ',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}