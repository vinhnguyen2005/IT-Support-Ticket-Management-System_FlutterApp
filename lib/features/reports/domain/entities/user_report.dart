class UserReport {
  const UserReport({
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
