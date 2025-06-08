import 'package:flutter/foundation.dart'; // For ChangeNotifier
import 'dart:collection'; // For UnmodifiableMapView

class CartProvider extends ChangeNotifier {
  final Map<int, int> _cartCounts = {};

  /// Returns an unmodifiable view of the cart items and their counts.
  /// Key: productId, Value: quantity
  Map<int, int> get cartCounts => UnmodifiableMapView(_cartCounts);

  /// Gets the quantity of a specific product in the cart.
  /// Returns 0 if the product is not in the cart.
  int getQuantity(int productId) {
    return _cartCounts[productId] ?? 0;
  }

  /// Adds one unit of the product to the cart.
  /// If the product is already in the cart, its quantity is incremented.
  void addToCart(int productId) {
    _cartCounts[productId] = (_cartCounts[productId] ?? 0) + 1;
    notifyListeners();
  }

  /// Sets the quantity for a specific product in the cart.
  /// If the count is less than or equal to 0, the product is removed from the cart.
  void setCartCount(int productId, int count) {
    if (count <= 0) {
      _cartCounts.remove(productId);
    } else {
      _cartCounts[productId] = count;
    }
    notifyListeners();
  }

  /// Decrements the quantity of a product by one.
  /// If the quantity becomes 0, the product is removed from the cart.
  void removeFromCart(int productId) {
    if (_cartCounts.containsKey(productId)) {
      int currentCount = _cartCounts[productId]!;
      if (currentCount > 1) {
        _cartCounts[productId] = currentCount - 1;
      } else {
        // If current count is 1 (or less, though not expected here), remove it
        _cartCounts.remove(productId);
      }
      notifyListeners();
    }
  }

  /// Removes all items from the cart.
  void clearCart() {
    if (_cartCounts.isNotEmpty) {
      _cartCounts.clear();
      notifyListeners();
    }
  }

  /// Calculates the total number of individual items in the cart.
  int get totalItems => _cartCounts.values.fold(0, (sum, count) => sum + count);

  /// Calculates the number of unique product types in the cart.
  int get uniqueItemsCount => _cartCounts.length;

  // Nếu bạn có thông tin về giá sản phẩm, bạn có thể thêm phương thức tính tổng tiền:
  // double calculateTotalPrice(List<Product> allProducts) {
  //   double total = 0;
  //   _cartCounts.forEach((productId, quantity) {
  //     final product = allProducts.firstWhere((p) => p.id == productId, orElse: () => null);
  //     if (product != null && product.price != null) {
  //       total += product.price! * quantity;
  //     }
  //   });
  //   return total;
  // }
}