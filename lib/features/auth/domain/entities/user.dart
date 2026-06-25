class User {
  const User({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.role,
    this.departmentId,
    this.phoneNumber,
    this.avatarUrl,
    required this.isActive,
    required this.mustChangePassword,
    this.lastLoginAt,
    required this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String fullName;
  final String username;
  final String email;
  final String role;
  final int? departmentId;
  final String? phoneNumber;
  final String? avatarUrl;
  final bool isActive;
  final bool mustChangePassword;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
