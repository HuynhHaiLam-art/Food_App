import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/home/background_widget.dart';
import '../widgets/cart/cart_item_widget.dart'; // Sửa đường dẫn
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        // Sử dụng đúng getter name từ CartProvider
        final totalPrice = cartProvider.items.entries.fold<double>(
          0.0,
          (sum, entry) {
            final product = entry.key;
            final quantity = entry.value;
            return sum + ((product.price ?? 0.0) * quantity);
          },
        );

        return BackgroundWidget(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Giỏ hàng'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: cartProvider.items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart, size: 64, color: Colors.white54),
                        SizedBox(height: 16),
                        Text(
                          'Giỏ hàng trống',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: cartProvider.items.length,
                          itemBuilder: (context, index) {
                            final entry = cartProvider.items.entries.elementAt(index);
                            final product = entry.key;
                            final quantity = entry.value;
                            return CartItemWidget(
                              product: product,
                              quantity: quantity,
                              onQuantityChanged: (newQuantity) {
                                if (newQuantity <= 0) {
                                  cartProvider.removeFromCart(product);
                                } else {
                                  cartProvider.updateQuantity(product, newQuantity);
                                }
                              },
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tổng cộng:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${totalPrice.toStringAsFixed(0)} VNĐ',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CheckoutScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Thanh toán'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}