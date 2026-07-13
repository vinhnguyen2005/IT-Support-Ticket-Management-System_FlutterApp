class StaffPerformanceReportDto {
  final int staffId;
  final String staffName;
  final int assignedTickets;
  final int resolvedTickets;

  StaffPerformanceReportDto({
    required this.staffId,
    required this.staffName,
    required this.assignedTickets,
    required this.resolvedTickets,
  });

  factory StaffPerformanceReportDto.fromMap(Map<String, dynamic> map) {
    return StaffPerformanceReportDto(
      staffId: map['staff_id'] as int? ?? 0,
      staffName: map['staff_name'] as String? ?? 'Unknown',
      assignedTickets: map['assigned_tickets'] as int? ?? 0,
      resolvedTickets: map['resolved_tickets'] as int? ?? 0,
    );
  }
}
