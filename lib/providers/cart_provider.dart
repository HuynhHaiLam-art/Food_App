import 'package:flutter/foundation.dart';
import '../models/cartitem.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final Map<int, int> _cartCounts = {}; // Key: productId, Value: quantity

  /// Getter cho danh sách CartItem (dùng cho API/checkout)
  List<CartItem> get items => List.unmodifiable(_items);

  /// Getter cho map đếm số lượng từng sản phẩm trong giỏ (dùng cho UI)
  Map<int, int> get cartCounts => Map.unmodifiable(_cartCounts);

  /// Tổng tiền dựa trên CartItem
  double get totalPrice => _items.fold(
      0, (sum, item) => sum + (item.price) * (item.quantity ?? 1));

  /// Lấy số lượng của một sản phẩm trong giỏ
  int getQuantity(int productId) {
    return _cartCounts[productId] ?? 0;
  }

  /// Thêm một sản phẩm vào giỏ (tăng số lượng nếu đã có)
  /// Luôn truyền vào cartItem có đủ thông tin Product
  void addToCart(Product product) {
    if (product.id == null) return;
    _cartCounts[product.id!] = (_cartCounts[product.id!] ?? 0) + 1;
    final index = _items.indexWhere((item) => item.foodId == product.id);
    if (index == -1) {
      _items.add(CartItem(
        foodId: product.id,
        food: product,
        quantity: 1,
      ));
    } else {
      _items[index] = _items[index].copyWith(
        quantity: _cartCounts[product.id!],
      );
    }
    notifyListeners();
  }

  /// Đặt số lượng cho một sản phẩm
  void setCartCount(int productId, int count) {
    if (count <= 0) {
      _cartCounts.remove(productId);
      _items.removeWhere((item) => item.foodId == productId);
    } else {
      _cartCounts[productId] = count;
      final index = _items.indexWhere((item) => item.foodId == productId);
      if (index != -1) {
        _items[index] = _items[index].copyWith(quantity: count);
      }
    }
    notifyListeners();
  }

  /// Giảm số lượng sản phẩm, nếu về 0 thì xóa khỏi giỏ
  void removeFromCart(int productId) {
    if (_cartCounts.containsKey(productId)) {
      int currentCount = _cartCounts[productId]!;
      if (currentCount > 1) {
        _cartCounts[productId] = currentCount - 1;
        final index = _items.indexWhere((item) => item.foodId == productId);
        if (index != -1) {
          _items[index] =
              _items[index].copyWith(quantity: _cartCounts[productId]);
        }
      } else {
        _cartCounts.remove(productId);
        _items.removeWhere((item) => item.foodId == productId);
      }
      notifyListeners();
    }
  }

  /// Xóa toàn bộ giỏ hàng
  void clearCart() {
    if (_cartCounts.isNotEmpty || _items.isNotEmpty) {
      _cartCounts.clear();
      _items.clear();
      notifyListeners();
    }
  }

  /// Tổng số lượng sản phẩm (tất cả)
  int get totalItems => _cartCounts.values.fold(0, (sum, count) => sum + count);

  /// Số loại sản phẩm khác nhau
  int get uniqueItemsCount => _cartCounts.length;
}