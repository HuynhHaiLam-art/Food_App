class UserUpdate {
  final String? name;
  final String? email;

  UserUpdate({
    this.name,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
    };
  }

  factory UserUpdate.fromJson(Map<String, dynamic> json) {
    return UserUpdate(
      name: json['name'],
      email: json['email'],
    );
  }
}