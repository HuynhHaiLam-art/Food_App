import 'dart:convert';

class UserCreate {
  final String name;
  final String email;
  final String password;
  final String role; // Mặc định là 'user'

  UserCreate({
    required this.name,
    required this.email,
    required this.password,
    this.role = 'user',
  });

  factory UserCreate.fromJson(Map<String, dynamic> json) {
    return UserCreate(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      };

  String toJsonString() => json.encode(toJson());

  factory UserCreate.fromJsonString(String source) =>
      UserCreate.fromJson(json.decode(source) as Map<String, dynamic>);

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