class Cartitem {
  int? id;
  int? userId;
  int? foodId;
  int? quantity;
  DateTime? createdAt; // Chuyển sang DateTime
  String? food; // Giữ là String nếu API trả về String, hoặc chuyển thành model Product nếu API trả về object Product
  String? user; // Giữ là String nếu API trả về String, hoặc chuyển thành model User nếu API trả về object User

  Cartitem({
    this.id,
    this.userId,
    this.foodId,
    this.quantity,
    this.createdAt,
    this.food,
    this.user,
  });

  factory Cartitem.fromJson(Map<String, dynamic> json) {
    return Cartitem(
      id: json['id'] as int?,
      userId: json['userId'] as int?,
      foodId: json['foodId'] as int?,
      quantity: json['quantity'] as int?,
      // Cẩn thận: Đảm bảo rằng json['createdAt'] là một chuỗi ISO 8601 hợp lệ hoặc null
      // Nếu định dạng ngày tháng từ API khác, bạn cần parse tương ứng.
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
      food: json['food'] as String?,
      user: json['user'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['userId'] = userId;
    data['foodId'] = foodId;
    data['quantity'] = quantity;
    // Chuyển DateTime thành chuỗi ISO 8601 khi gửi lên server
    data['createdAt'] = createdAt?.toIso8601String();
    data['food'] = food;
    data['user'] = user;
    return data;
  }

  Cartitem copyWith({
    int? id,
    int? userId,
    int? foodId,
    int? quantity,
    DateTime? createdAt,
    String? food,
    String? user,
  }) {
    return Cartitem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodId: foodId ?? this.foodId,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      food: food ?? this.food,
      user: user ?? this.user,
    );
  }

  @override
  String toString() {
    return 'Cartitem(id: $id, userId: $userId, foodId: $foodId, quantity: $quantity, createdAt: $createdAt, food: $food, user: $user)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Cartitem &&
        other.id == id &&
        other.userId == userId &&
        other.foodId == foodId &&
        other.quantity == quantity &&
        other.createdAt == createdAt &&
        other.food == food &&
        other.user == user;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        foodId.hashCode ^
        quantity.hashCode ^
        createdAt.hashCode ^
        food.hashCode ^
        user.hashCode;
  }
}