class StaffPerformanceReport {
  final int staffId;
  final String staffName;
  final int assignedTickets; // Tổng số ticket được giao
  final int resolvedTickets; // Số ticket đã giải quyết xong

  StaffPerformanceReport({
    required this.staffId,
    required this.staffName,
    required this.assignedTickets,
    required this.resolvedTickets,
  });
}
