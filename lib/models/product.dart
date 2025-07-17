// Cần thiết cho việc so sánh bằng jsonEncode nếu có list/map phức tạp
class Product {
  int? id;
  String? name;
  String? description;
  double? price;
  String? imageUrl;
  int? categoryId;
  String? categoryName; // Field từ JOIN với Categories table

  Product({
    this.id,
    this.name,
    this.description,
    this.price,
    this.imageUrl,
    this.categoryId,
    this.categoryName,
  });

  // ✅ THÊM: copyWith method
  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    int? categoryId,
    String? categoryName,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (price != null) data['price'] = price;
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (categoryId != null) data['categoryId'] = categoryId;
    if (categoryName != null) data['categoryName'] = categoryName;
    return data;
  }

  // Override equality để CartProvider hoạt động đúng
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}