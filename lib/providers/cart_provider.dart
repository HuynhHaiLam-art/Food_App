import 'package:flutter/material.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final Map<Product, int> _items = {};

  // Getter cho items
  Map<Product, int> get items => Map.from(_items);
  
  // Getter cho compatibility với code cũ
  Map<Product, int> get cartItems => Map.from(_items);

  int get itemCount => _items.values.fold(0, (sum, quantity) => sum + quantity);

  double get totalPrice {
    return _items.entries.fold(0.0, (sum, entry) {
      final product = entry.key;
      final quantity = entry.value;
      return sum + ((product.price ?? 0.0) * quantity);
    });
  }

  // Lấy số lượng của sản phẩm trong giỏ hàng theo ID
  Map<int, int> get cartCounts {
    final counts = <int, int>{};
    for (final entry in _items.entries) {
      final productId = entry.key.id;
      if (productId != null) {
        counts[productId] = entry.value;
      }
    }
    return counts;
  }

  // Thêm sản phẩm vào giỏ hàng
  void addToCart(Product product) {
    if (_items.containsKey(product)) {
      _items[product] = _items[product]! + 1;
    } else {
      _items[product] = 1;
    }
    notifyListeners();
  }

  // Xóa sản phẩm khỏi giỏ hàng (giảm 1 hoặc xóa hoàn toàn)
  void removeFromCart(dynamic productOrId) {
    if (productOrId is Product) {
      // Truyền vào Product object
      if (_items.containsKey(productOrId)) {
        if (_items[productOrId]! > 1) {
          _items[productOrId] = _items[productOrId]! - 1;
        } else {
          _items.remove(productOrId);
        }
        notifyListeners();
      }
    } else if (productOrId is int) {
      // Truyền vào product ID
      final productToRemove = _items.keys.firstWhere(
        (product) => product.id == productOrId,
        orElse: () => Product(), // Return empty product if not found
      );
      
      if (productToRemove.id != null && _items.containsKey(productToRemove)) {
        if (_items[productToRemove]! > 1) {
          _items[productToRemove] = _items[productToRemove]! - 1;
        } else {
          _items.remove(productToRemove);
        }
        notifyListeners();
      }
    }
  }

  // Cập nhật số lượng sản phẩm
  void updateQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      _items.remove(product);
    } else {
      _items[product] = quantity;
    }
    notifyListeners();
  }

  // Xóa toàn bộ giỏ hàng
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}