import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/addon.dart';

class CartItem {
  final Product product;
  final List<AddOn> addOns;
  int quantity;

  CartItem({
    required this.product,
    this.addOns = const [],
    this.quantity = 1,
  });

  // So sánh sản phẩm và addOns để phân biệt CartItem
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.product.id == product.id &&
        _compareAddOns(other.addOns, addOns);
  }

  @override
  int get hashCode => Object.hash(product.id, _hashAddOns(addOns));

  static bool _compareAddOns(List<AddOn> a, List<AddOn> b) {
    if (a.length != b.length) return false;
    for (final addon in a) {
      if (!b.any((other) => other.name == addon.name && other.price == addon.price)) {
        return false;
      }
    }
    return true;
  }

  static int _hashAddOns(List<AddOn> addOns) {
    return addOns.fold(0, (prev, a) => prev ^ a.name.hashCode ^ a.price.hashCode);
  }

  double get totalPrice =>
      ((product.price ?? 0) +
          addOns.fold<int>(0, (sum, addon) => sum + (addon.price))) *
      quantity;
}

class CartProvider extends ChangeNotifier {
  // Danh sách CartItem thay cho Map<Product, int> cũ.
  final List<CartItem> _items = [];

  // Đảm bảo compatibility: Map<Product, int> getter cho code cũ (không có addOns)
  Map<Product, int> get items {
    var map = <Product, int>{};
    for (final item in _items) {
      map[item.product] = (map[item.product] ?? 0) + item.quantity;
    }
    return map;
  }

  // Getter mới: lấy full CartItem để xử lý addOns
  List<CartItem> get cartItems => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Đếm số lượng cho từng productId (bất kể addOns)
  Map<int, int> get cartCounts {
    final counts = <int, int>{};
    for (final item in _items) {
      final productId = item.product.id;
      if (productId != null) {
        counts[productId] = (counts[productId] ?? 0) + item.quantity;
      }
    }
    return counts;
  }

  // Thêm sản phẩm vào giỏ, có thể có addOns
  void addToCart(Product product, {List<AddOn> addOns = const []}) {
    final index = _items.indexWhere((item) =>
        item.product.id == product.id &&
        CartItem._compareAddOns(item.addOns, addOns));
    if (index != -1) {
      _items[index].quantity += 1;
    } else {
      _items.add(CartItem(product: product, addOns: List.from(addOns), quantity: 1));
    }
    notifyListeners();
  }

  // Xóa sản phẩm khỏi giỏ (giảm 1 hoặc xóa hoàn toàn), cần truyền đúng addOns nếu có
  void removeFromCart(Product product, {List<AddOn> addOns = const []}) {
    final index = _items.indexWhere((item) =>
        item.product.id == product.id &&
        CartItem._compareAddOns(item.addOns, addOns));
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Cập nhật số lượng CartItem (theo product và addOns)
  void updateQuantity(Product product, int quantity, {List<AddOn> addOns = const []}) {
    final index = _items.indexWhere((item) =>
        item.product.id == product.id &&
        CartItem._compareAddOns(item.addOns, addOns));
    if (index != -1) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  // Xóa toàn bộ giỏ hàng
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}