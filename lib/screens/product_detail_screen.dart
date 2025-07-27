import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../models/addon.dart';
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';
import '../utils/formatters.dart';
import '../widgets/home/background_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Add-on mẫu
  final List<AddOn> addOns = [
    AddOn(name: 'Khoai tây chiên', price: 15000),
    AddOn(name: 'Phô mai lát', price: 10000),
    AddOn(name: 'Nước ngọt', price: 12000),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// So sánh hai list AddOn (bắt chước static _compareAddOns trong CartProvider)
  bool compareAddOns(List<AddOn> a, List<AddOn> b) {
    if (a.length != b.length) return false;
    for (final addon in a) {
      if (!b.any((other) => other.name == addon.name && other.price == addon.price)) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final productId = product.id;
    if (productId == null) {
      return Scaffold(
        body: BackgroundWidget(
          child: Center(
            child: Text(
              'Sản phẩm không hợp lệ',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            // Custom App Bar with Hero Image
            SliverAppBar(
              expandedHeight: 350,
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                Consumer<FavoriteProvider>(
                  builder: (context, favoriteProvider, _) {
                    final isFavorite = favoriteProvider.isFavorite(productId);
                    return Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.white,
                        ),
                        onPressed: () => favoriteProvider.toggleFavorite(productId),
                      ),
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'product_$productId',
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl ??
                            'https://via.placeholder.com/400x300.png?text=No+Image',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFF21262D),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF6B35),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFF21262D),
                          child: const Icon(
                            Icons.fastfood,
                            size: 80,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Color(0x80000000),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Details
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0x1AFFFFFF),
                              Color(0x0DFFFFFF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Name
                              Text(
                                product.name ?? 'N/A',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (product.categoryName != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF6B35), Color(0xFFFF8F65)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    product.categoryName!,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Text(
                                formatCurrency(product.price ?? 0.0),
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFFC107),
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (product.description != null &&
                                  product.description!.isNotEmpty) ...[
                                Text(
                                  'Mô tả',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product.description!,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // --- Add-ons Section ---
                              Text(
                                'Chọn sản phẩm phụ',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...addOns.map((addon) => CheckboxListTile(
                                    value: addon.selected,
                                    onChanged: (checked) {
                                      setState(() {
                                        addon.selected = checked ?? false;
                                      });
                                    },
                                    title: Text(
                                      '${addon.name} (+${addon.price}₫)',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    controlAffinity: ListTileControlAffinity.leading,
                                    activeColor: Colors.orange,
                                    contentPadding: EdgeInsets.zero,
                                  )),
                              const SizedBox(height: 20),

                              // --- Quantity and Add to Cart Section ---
                              Consumer<CartProvider>(
                                builder: (context, cartProvider, _) {
                                  // Lấy số lượng CartItem đúng theo productId và addOns đã chọn
                                  final selectedAddOns =
                                      addOns.where((a) => a.selected).toList();
                                  final cartItem = cartProvider.cartItems.firstWhere(
                                    (item) =>
                                        item.product.id == productId &&
                                        compareAddOns(item.addOns, selectedAddOns),
                                    orElse: () => CartItem(product: product),
                                  );
                                  final cartCount = cartItem.quantity;

                                  return Row(
                                    children: [
                                      if (cartCount > 0) ...[
                                        _QuantityButton(
                                          icon: Icons.remove,
                                          onPressed: () {
                                            cartProvider.removeFromCart(
                                              product,
                                              addOns: selectedAddOns,
                                            );
                                          },
                                          isDecrease: true,
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '$cartCount',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                      Expanded(
                                        child: Container(
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFFF6B35),
                                                Color(0xFFFF8F65)
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFF6B35)
                                                    .withOpacity(0.3),
                                                blurRadius: 15,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              onTap: () {
                                                cartProvider.addToCart(
                                                  product,
                                                  addOns: selectedAddOns,
                                                );
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Đã thêm ${product.name}${selectedAddOns.isNotEmpty ? ' (+${selectedAddOns.map((a) => a.name).join(", ")})' : ''} vào giỏ hàng',
                                                      style: GoogleFonts.inter(),
                                                    ),
                                                    backgroundColor:
                                                        const Color(0xFFFF6B35),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Center(
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.add_shopping_cart,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      cartCount > 0
                                                          ? 'Thêm nữa'
                                                          : 'Thêm vào giỏ',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDecrease;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    this.isDecrease = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: isDecrease
            ? const LinearGradient(colors: [Colors.red, Colors.redAccent])
            : const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8F65)]),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:
                (isDecrease ? Colors.red : const Color(0xFFFF6B35))
                    .withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}