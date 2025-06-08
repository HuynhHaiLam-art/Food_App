
class UserCreate {
  final String name;
  final String email;
  final String password;
  final String role; // Role có thể được chỉ định, mặc định là 'user'

  UserCreate({
    required this.name,
    required this.email,
    required this.password,
    this.role = 'user', // Giá trị mặc định nếu không được cung cấp
  });

  factory UserCreate.fromJson(Map<String, dynamic> json) {
    // Constructor fromJson thường ít dùng cho DTO gửi đi,
    // nhưng nếu có, nó nên xử lý các giá trị null một cách an toàn.
    return UserCreate(
      name: json['name'] as String? ?? '', // Xử lý null tiềm ẩn từ API/JSON
      email: json['email'] as String? ?? '', // Xử lý null tiềm ẩn từ API/JSON
      password: json['password'] as String? ?? '', // Xử lý null tiềm ẩn từ API/JSON
      role: json['role'] as String? ?? 'user', // Xử lý null, giữ giá trị mặc định
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['email'] = email;
    data['password'] = password;
    data['role'] = role;
    return data;
  }

  UserCreate copyWith({
    String? name,
    String? email,
    String? password,
    String? role,
  }) {
    return UserCreate(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'UserCreate(name: $name, email: $email, password: $password, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserCreate &&
        other.name == name &&
        other.email == email &&
        other.password == password &&
        other.role == role;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        email.hashCode ^
        password.hashCode ^
        role.hashCode;
  }
}