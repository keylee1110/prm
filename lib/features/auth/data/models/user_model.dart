class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? role;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
    };
  }
}
