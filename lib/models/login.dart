import 'dart:convert';

class LoginDTO {
  final String email;
  final String password;

  LoginDTO({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };

  // Factory constructor fromJson (ít phổ biến cho DTO gửi đi, nhưng có thể hữu ích)
  factory LoginDTO.fromJson(Map<String, dynamic> json) {
    return LoginDTO(
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }

  // Tiện ích để chuyển đổi từ/sang chuỗi JSON (nếu cần)
  String toJsonString() => json.encode(toJson());
  factory LoginDTO.fromJsonString(String source) => LoginDTO.fromJson(json.decode(source) as Map<String, dynamic>);

  LoginDTO copyWith({
    String? email,
    String? password,
  }) {
    return LoginDTO(
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  @override
  String toString() => 'LoginDTO(email: $email, password: $password)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoginDTO &&
        other.email == email &&
        other.password == password;
  }

  @override
  int get hashCode => email.hashCode ^ password.hashCode;
}