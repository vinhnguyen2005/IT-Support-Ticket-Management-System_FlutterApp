import '../../../../core/enums/sla_status.dart';

class SlaAttentionReportDto {
  const SlaAttentionReportDto({
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

  factory SlaAttentionReportDto.fromMap(Map<String, Object?> map) {
    final rawStatus = map['sla_status'] as String? ?? SlaStatus.atRisk.name;
    return SlaAttentionReportDto(
      ticketId: map['ticket_id'] as int,
      title: map['title'] as String,
      priority: map['priority'] as String,
      ticketStatus: map['ticket_status'] as String,
      slaStatus: SlaStatus.values.firstWhere(
        (status) => status.name == rawStatus,
        orElse: () => SlaStatus.atRisk,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      resolutionDueAt: DateTime.parse(map['resolution_due_at'] as String),
      staffName: map['staff_name'] as String?,
      categoryName: map['category_name'] as String?,
    );
  }
}
