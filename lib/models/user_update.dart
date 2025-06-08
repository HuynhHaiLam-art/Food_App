
class UserUpdate {
  final String? name;
  final String? email;
  final String? role;
  // Bạn có thể thêm các trường khác có thể cập nhật, ví dụ:
  // final String? avatarUrl;
  // final String? currentPassword; // Nếu cập nhật mật khẩu yêu cầu mật khẩu hiện tại
  // final String? newPassword;     // Mật khẩu mới

  UserUpdate({
    this.name,
    this.email,
    this.role,
    // this.avatarUrl,
    // this.currentPassword,
    // this.newPassword,
  });

  factory UserUpdate.fromJson(Map<String, dynamic> json) {
    // fromJson cho DTO cập nhật thường ít dùng vì DTO này chủ yếu để gửi đi.
    // Nếu dùng, nó sẽ đọc các giá trị có thể có.
    return UserUpdate(
      name: json['name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      // avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    // Chỉ thêm vào JSON nếu giá trị không null
    if (name != null) {
      data['name'] = name;
    }
    if (email != null) {
      data['email'] = email;
    }
    if (role != null) {
      data['role'] = role;
    }
    // if (avatarUrl != null) {
    //   data['avatarUrl'] = avatarUrl;
    // }
    // if (currentPassword != null) {
    //   data['currentPassword'] = currentPassword;
    // }
    // if (newPassword != null) {
    //   data['newPassword'] = newPassword;
    // }
    return data;
  }

  UserUpdate copyWith({
    String? name,
    String? email,
    String? role,
    // String? avatarUrl,
    // String? currentPassword,
    // String? newPassword,
  }) {
    return UserUpdate(
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      // avatarUrl: avatarUrl ?? this.avatarUrl,
      // currentPassword: currentPassword ?? this.currentPassword,
      // newPassword: newPassword ?? this.newPassword,
    );
  }

  @override
  String toString() {
    return 'UserUpdate(name: $name, email: $email, role: $role)';
    // Thêm các trường khác nếu có: ', avatarUrl: $avatarUrl, currentPassword: $currentPassword, newPassword: $newPassword)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserUpdate &&
        other.name == name &&
        other.email == email &&
        other.role == role;
        // && other.avatarUrl == avatarUrl
        // && other.currentPassword == currentPassword
        // && other.newPassword == newPassword;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        email.hashCode ^
        role.hashCode;
        // ^ avatarUrl.hashCode
        // ^ currentPassword.hashCode
        // ^ newPassword.hashCode;
  }
}