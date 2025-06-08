
class User {
  final int? id;
  final String? name;
  final String? email;
  final String? role;
  // Bạn có thể thêm các trường khác mà API trả về, ví dụ:
  // final DateTime? createdAt;
  // final DateTime? updatedAt;
  // final String? avatarUrl;

  User({
    this.id,
    this.name,
    this.email,
    this.role,
    // this.createdAt,
    // this.updatedAt,
    // this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      // createdAt: json['createdAt'] == null ? null : DateTime.tryParse(json['createdAt'] as String),
      // updatedAt: json['updatedAt'] == null ? null : DateTime.tryParse(json['updatedAt'] as String),
      // avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['role'] = role;
    // data['createdAt'] = createdAt?.toIso8601String();
    // data['updatedAt'] = updatedAt?.toIso8601String();
    // data['avatarUrl'] = avatarUrl;
    return data;
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    // DateTime? createdAt,
    // DateTime? updatedAt,
    // String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      // createdAt: createdAt ?? this.createdAt,
      // updatedAt: updatedAt ?? this.updatedAt,
      // avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: $role)';
    // Thêm các trường khác nếu có: ', createdAt: $createdAt, updatedAt: $updatedAt, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.role == role;
        // && other.createdAt == createdAt
        // && other.updatedAt == updatedAt
        // && other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        role.hashCode;
        // ^ createdAt.hashCode
        // ^ updatedAt.hashCode
        // ^ avatarUrl.hashCode;
  }
}