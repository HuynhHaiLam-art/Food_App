import 'dart:convert'; // Cần nếu foods là List<SomeModel> và bạn muốn tự encode/decode

class Category {
  final int id;
  final String name;
  final List<String> foods; // Giả sử 'foods' là danh sách các tên hoặc ID của món ăn

  Category({
    required this.id,
    required this.name,
    required this.foods,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int? ?? 0, // Cung cấp giá trị mặc định nếu null
      name: json['name'] as String? ?? '', // Cung cấp giá trị mặc định nếu null
      // Đảm bảo rằng 'foods' là một List và các phần tử của nó có thể được chuyển thành String
      foods: (json['foods'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [], // Cung cấp giá trị mặc định là list rỗng nếu null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'foods': foods, // Nếu foods là List<SomeModel>, bạn cần map qua và gọi toJson() cho từng item
    };
  }

  Category copyWith({
    int? id,
    String? name,
    List<String>? foods,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      foods: foods ?? this.foods,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, foods: $foods)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    // Sử dụng jsonEncode để so sánh list một cách đơn giản,
    // hoặc bạn có thể dùng collection package's ListEquality.
    return other is Category &&
        other.id == id &&
        other.name == name &&
        jsonEncode(other.foods) == jsonEncode(foods); // So sánh list
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        foods.hashCode; // hashCode của List đã được implement đúng
  }
}