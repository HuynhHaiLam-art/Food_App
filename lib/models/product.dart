 // Cần thiết cho việc so sánh bằng jsonEncode nếu có list/map phức tạp
class Product {
  final int? id;
  final String? name;
  final String? description;
  final int? price; // Giữ là int nếu bạn muốn giá là số nguyên (ví dụ: đơn vị VNĐ)
  final String? imageUrl;
  final int? categoryId;
  final String? categoryName;

  Product({
    this.id,
    this.name,
    this.description,
    this.price,
    this.imageUrl,
    this.categoryId,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    num? priceValue = json['price'] as num?; // Đọc giá trị dưới dạng num?

    return Product(
      id: json['id'] as int?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      // Chuyển đổi priceValue sang int? một cách an toàn
      price: priceValue?.toInt(),
      imageUrl: json['imageUrl'] as String?,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['price'] = price;
    data['imageUrl'] = imageUrl;
    data['categoryId'] = categoryId;
    data['categoryName'] = categoryName;
    return data;
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    int? price,
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

  @override
  String toString() {
    return 'Product(id: $id, name: $name, description: $description, price: $price, imageUrl: $imageUrl, categoryId: $categoryId, categoryName: $categoryName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Product &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.price == price &&
        other.imageUrl == imageUrl &&
        other.categoryId == categoryId &&
        other.categoryName == categoryName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        price.hashCode ^
        imageUrl.hashCode ^
        categoryId.hashCode ^
        categoryName.hashCode;
  }
}