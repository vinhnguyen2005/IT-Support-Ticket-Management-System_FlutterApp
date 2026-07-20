import '../../../../core/enums/sla_status.dart';

class Assignment {
  const Assignment({
    required this.id,
    required this.ticketId,
    required this.staffId,
    this.assignedByUserId,
    required this.assignedAt,
    this.note,
    required this.isActive,
    required this.ticketTitle,
    required this.ticketDescription,
    required this.issueType,
    required this.priority,
    required this.status,
    required this.ticketCreatedAt,
    this.ticketUpdatedAt,
    this.lastProgressMessage,
    this.firstRespondedAt,
    this.responseDueAt,
    this.resolutionDueAt,
    this.slaCompletedAt,
    this.slaExceptionReason,
  });

  final int id;
  final int ticketId;
  final int staffId;
  final int? assignedByUserId;
  final DateTime assignedAt;
  final String? note;
  final bool isActive;
  final String ticketTitle;
  final String ticketDescription;
  final String issueType;
  final String priority;
  final String status;
  final DateTime ticketCreatedAt;
  final DateTime? ticketUpdatedAt;
  final String? lastProgressMessage;
  final DateTime? firstRespondedAt;
  final DateTime? responseDueAt;
  final DateTime? resolutionDueAt;
  final DateTime? slaCompletedAt;
  final String? slaExceptionReason;

  bool get isClosed => status.toLowerCase() == 'closed';

  SlaStatus resolutionSlaStatusAt(DateTime now) {
    if (status.toLowerCase() == 'cancelled' || slaExceptionReason != null) {
      return SlaStatus.exempt;
    }
    final dueAt = resolutionDueAt;
    if (dueAt == null) return SlaStatus.onTrack;
    if (slaCompletedAt != null) {
      return slaCompletedAt!.isAfter(dueAt)
          ? SlaStatus.breachedResolved
          : SlaStatus.met;
    }
    if (!now.isBefore(dueAt)) return SlaStatus.breached;
    final total = dueAt.difference(ticketCreatedAt).inMilliseconds;
    final elapsed = now.difference(ticketCreatedAt).inMilliseconds;
    return total > 0 && elapsed / total >= 0.75
        ? SlaStatus.atRisk
        : SlaStatus.onTrack;
  }
}
