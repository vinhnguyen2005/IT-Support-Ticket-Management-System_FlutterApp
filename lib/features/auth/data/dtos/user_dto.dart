class UserDto {
  const UserDto({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.passwordHash,
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
  final String? passwordHash;
  final String role;
  final int? departmentId;
  final String? phoneNumber;
  final String? avatarUrl;
  final bool isActive;
  final bool mustChangePassword;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory UserDto.fromMap(Map<String, Object?> map) {
    return UserDto(
      id: map['id'] as int,
      fullName: map['fullName'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      passwordHash: map['passwordHash'] as String?,
      role: map['role'] as String,
      departmentId: map['departmentId'] as int?,
      phoneNumber: map['phoneNumber'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      isActive: (map['isActive'] as int) == 1,
      mustChangePassword: (map['mustChangePassword'] as int) == 1,
      lastLoginAt: map['lastLoginAt'] == null
          ? null
          : DateTime.parse(map['lastLoginAt'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] == null
          ? null
          : DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      'email': email,
      'passwordHash': passwordHash,
      'role': role,
      'departmentId': departmentId,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'isActive': isActive ? 1 : 0,
      'mustChangePassword': mustChangePassword ? 1 : 0,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
