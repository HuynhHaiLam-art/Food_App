import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/product_provider.dart';
import '../utils/formatters.dart';
import '../widgets/home/background_widget.dart';
import 'product_detail_screen.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final favoriteIds = favoriteProvider.favoriteProductIds;
    final favoriteProducts = productProvider.products
        .where((p) => p.id != null && favoriteIds.contains(p.id))
        .toList();

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Yêu thích', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
        ),
        body: favoriteProducts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.favorite, color: Colors.pinkAccent, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Chưa có sản phẩm yêu thích nào.',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favoriteProducts.length,
                itemBuilder: (context, index) {
                  final product = favoriteProducts[index];
                  return Card(
                    color: Colors.white.withOpacity(0.08),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: product.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product.imageUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(Icons.fastfood, color: Colors.white54),
                              ),
                            )
                          : const Icon(Icons.fastfood, color: Colors.white54),
                      title: Text(
                        product.name ?? 'Sản phẩm',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        formatCurrency(product.price),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
                        onPressed: () {
                          if (product.id != null) {
                            favoriteProvider.toggleFavorite(product.id!);
                          }
                        },
                        tooltip: 'Bỏ khỏi yêu thích',
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: product),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}