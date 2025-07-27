import 'product.dart';
import 'addon.dart';

class CartItem {
  int? id;
  int? userId;
  int? foodId;
  int? quantity;
  DateTime? createdAt;
  Product? food;
  List<AddOn> addOns;

  CartItem({
    this.id,
    this.userId,
    this.foodId,
    this.quantity,
    this.createdAt,
    this.food,this.addOns = const [],
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int?,
      userId: json['userId'] as int?,
      foodId: json['foodId'] as int?,
      quantity: json['quantity'] as int?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
      food: json['food'] != null && json['food'] is Map<String, dynamic>
          ? Product.fromJson(json['food'] as Map<String, dynamic>)
          : null,
      addOns: (json['addOns'] as List<dynamic>?)
              ?.map((e) => AddOn.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],     
    );
  }

  /// Nếu forOrder = true, chỉ trả về các trường cần thiết cho order detail.
  Map<String, dynamic> toJson({bool forOrder = false}) {
    if (forOrder) {
      final data = <String, dynamic>{
        'foodId': foodId,
        'foodName': food?.name,
        'quantity': quantity,
        'price': food?.price,
        'addOns': addOns.map((e) => e.toJson()).toList(),
      };
      data.removeWhere((key, value) => value == null);
      return data;
    }
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (userId != null) data['userId'] = userId;
    if (foodId != null) data['foodId'] = foodId;
    if (quantity != null) data['quantity'] = quantity;
    if (createdAt != null) data['createdAt'] = createdAt?.toIso8601String();
    if (food != null) data['food'] = food?.toJson();
    if (addOns.isNotEmpty) data['addOns'] = addOns.map((e) => e.toJson()).toList();
    data.removeWhere((key, value) => value == null);
    return data;
  }

  CartItem copyWith({
    int? id,
    int? userId,
    int? foodId,
    int? quantity,
    DateTime? createdAt,
    Product? food,
    List<AddOn>? addOns,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodId: foodId ?? this.foodId,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      food: food ?? this.food,
      addOns: addOns ?? this.addOns,
    );
  }

  // Getter tiện ích cho UI
  double get price =>
      (food?.price ?? 0).toDouble() +
      addOns.fold(0, (sum, a) => sum + a.price);
  String get foodName => food?.name ?? '';
  String? get imageUrl => food?.imageUrl;
  double get totalPrice => price * (quantity ?? 1);
}