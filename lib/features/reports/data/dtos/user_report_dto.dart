class UserReportDto {
  const UserReportDto({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.role,
    required this.isActive,
    required this.createdTickets,
    required this.completedTickets,
    this.departmentName,
    this.lastLoginAt,
  });

  factory UserReportDto.fromMap(Map<String, Object?> map) {
    final lastLoginValue = map['last_login_at'] as String?;
    return UserReportDto(
      userId: (map['user_id'] as num?)?.toInt() ?? 0,
      fullName: map['full_name'] as String? ?? 'Unknown',
      username: map['username'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
      departmentName: map['department_name'] as String?,
      isActive: (map['is_active'] as num?)?.toInt() == 1,
      lastLoginAt: lastLoginValue == null
          ? null
          : DateTime.tryParse(lastLoginValue),
      createdTickets: (map['created_tickets'] as num?)?.toInt() ?? 0,
      completedTickets: (map['completed_tickets'] as num?)?.toInt() ?? 0,
    );
  }

  final int userId;
  final String fullName;
  final String username;
  final String role;
  final String? departmentName;
  final bool isActive;
  final DateTime? lastLoginAt;
  final int createdTickets;
  final int completedTickets;
}
