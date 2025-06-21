import 'dart:convert';

class RegisterDTO {
  final String name;
  final String email;
  final String password;
  final String role; // Mặc định là 'user'

  RegisterDTO({
    required this.name,
    required this.email,
    required this.password,
    this.role = 'user',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      };

  factory RegisterDTO.fromJson(Map<String, dynamic> json) {
    return RegisterDTO(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
    );
  }

  String toJsonString() => json.encode(toJson());

  factory RegisterDTO.fromJsonString(String source) =>
      RegisterDTO.fromJson(json.decode(source) as Map<String, dynamic>);

  RegisterDTO copyWith({
    String? name,
    String? email,
    String? password,
    String? role,
  }) {
    return RegisterDTO(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'RegisterDTO(name: $name, email: $email, password: $password, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RegisterDTO &&
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