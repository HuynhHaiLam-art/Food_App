import 'package:collection/collection.dart';
class Category {
  final int id;
  final String name;
  final List<String> foods; // Nếu là List<int> thì đổi lại cho đúng

  Category({
    required this.id,
    required this.name,
    required this.foods,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      foods: (json['foods'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'foods': foods,
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
    return other is Category &&
        other.id == id &&
        other.name == name &&
        const ListEquality().equals(other.foods, foods);
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ const ListEquality().hash(foods);
}