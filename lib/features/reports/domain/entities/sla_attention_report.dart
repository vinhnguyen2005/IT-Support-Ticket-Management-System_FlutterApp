import '../../../../core/enums/sla_status.dart';

class SlaAttentionReport {
  const SlaAttentionReport({
    required this.ticketId,
    required this.title,
    required this.priority,
    required this.ticketStatus,
    required this.slaStatus,
    required this.createdAt,
    required this.resolutionDueAt,
    this.staffName,
    this.categoryName,
  });

  final int ticketId;
  final String title;
  final String priority;
  final String ticketStatus;
  final SlaStatus slaStatus;
  final DateTime createdAt;
  final DateTime resolutionDueAt;
  final String? staffName;
  final String? categoryName;

  Duration remainingAt(DateTime now) => resolutionDueAt.difference(now);
}
