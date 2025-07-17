import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_app/models/product.dart';
import 'package:food_app/themes/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final int cartCount;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onTap; // ✅ Thêm callback cho navigation

  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.cartCount,
    required this.onFavorite,
    required this.onAdd,
    this.onRemove,
    this.onTap, // ✅ Thêm parameter
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassMorphism,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap, // ✅ Sử dụng callback từ parent
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✨ Image Container with Gradient Overlay
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      // Product Image
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl ??
                                'https://via.placeholder.com/300x200.png?text=No+Image',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.surfaceColor,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryOrange,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.surfaceColor,
                              child: const Icon(
                                Icons.fastfood,
                                size: 48,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Gradient Overlay
                      Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0x40000000),
                            ],
                          ),
                        ),
                      ),

                      // Favorite Button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.white,
                              size: 20,
                            ),
                            onPressed: onFavorite,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),

                      // Cart Count Badge
                      if (cartCount > 0)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.buttonGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryOrange.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '$cartCount',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      // ✅ Tap indicator overlay
                      if (onTap != null)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.visibility,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ✨ Content Section
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          product.name ?? 'N/A',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Description
                        if (product.description != null &&
                            product.description!.isNotEmpty)
                          Text(
                            product.description!,
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                        const Spacer(),

                        // Price and Add Button Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Price
                            Text(
                              '${(product.price ?? 0.0).toStringAsFixed(0)} VNĐ',
                              style: GoogleFonts.poppins(
                                color: AppTheme.accentYellow,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // Add/Remove Buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (cartCount > 0 && onRemove != null)
                                  _ActionButton(
                                    icon: Icons.remove,
                                    onPressed: onRemove!,
                                    isRemove: true,
                                  ),

                                if (cartCount > 0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '$cartCount',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),

                                _ActionButton(
                                  icon: Icons.add,
                                  onPressed: onAdd,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isRemove;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    this.isRemove = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // ✅ Stop event propagation
        onPressed();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: isRemove
              ? const LinearGradient(colors: [Colors.red, Colors.redAccent])
              : AppTheme.buttonGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isRemove ? Colors.red : AppTheme.primaryOrange)
                  .withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}