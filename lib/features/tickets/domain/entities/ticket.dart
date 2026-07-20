import '../../../../core/enums/issue_type.dart';
import '../../../../core/enums/priority_level.dart';
import '../../../../core/enums/sla_status.dart';
import '../../../../core/enums/ticket_status.dart';

class Ticket {
  const Ticket({
    this.id,
    required this.title,
    required this.description,
    this.status = TicketStatus.defaultValue,
    this.priority = PriorityLevel.defaultValue,
    this.issueType = IssueType.defaultValue,
    this.attachmentUrl,
    this.requestedId,
    this.assignedId,
    this.categoryId,
    this.solutionSummary,
    this.resolvedAt,
    this.firstRespondedAt,
    this.responseDueAt,
    this.resolutionDueAt,
    this.slaCompletedAt,
    this.slaBreachedAt,
    this.slaExceptionReason,
    this.slaExceptionApprovedBy,
    required this.createdAt,
    this.updatedAt,
    this.createdByUserId,
    this.updatedByUserId,
    this.isDeleted = false,
  });

  final int? id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String issueType;
  final String? attachmentUrl;
  final int? requestedId;
  final int? assignedId;
  final int? categoryId;
  final String? solutionSummary;
  final DateTime? resolvedAt;
  final DateTime? firstRespondedAt;
  final DateTime? responseDueAt;
  final DateTime? resolutionDueAt;
  final DateTime? slaCompletedAt;
  final DateTime? slaBreachedAt;
  final String? slaExceptionReason;
  final int? slaExceptionApprovedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? createdByUserId;
  final int? updatedByUserId;
  final bool isDeleted;

  bool get isResolved => TicketStatus.fromValue(status).isResolved;

  bool get isOpen => !isResolved && !isDeleted;

  SlaStatus get resolutionSlaStatus => resolutionSlaStatusAt(DateTime.now());

  SlaStatus resolutionSlaStatusAt(DateTime now) {
    if (TicketStatus.fromValue(status) == TicketStatus.cancelled ||
        slaExceptionReason != null) {
      return SlaStatus.exempt;
    }

    final dueAt = resolutionDueAt;
    if (dueAt == null) {
      return SlaStatus.onTrack;
    }

    final completedAt = slaCompletedAt ?? resolvedAt;
    if (completedAt != null) {
      return completedAt.isAfter(dueAt)
          ? SlaStatus.breachedResolved
          : SlaStatus.met;
    }

    if (!now.isBefore(dueAt)) {
      return SlaStatus.breached;
    }

    final total = dueAt.difference(createdAt).inMilliseconds;
    final elapsed = now.difference(createdAt).inMilliseconds;
    if (total > 0 && elapsed / total >= 0.75) {
      return SlaStatus.atRisk;
    }
    return SlaStatus.onTrack;
  }

  SlaStatus responseSlaStatusAt(DateTime now) {
    if (TicketStatus.fromValue(status) == TicketStatus.cancelled ||
        slaExceptionReason != null) {
      return SlaStatus.exempt;
    }
    final dueAt = responseDueAt;
    if (dueAt == null) return SlaStatus.onTrack;
    if (firstRespondedAt != null) {
      return firstRespondedAt!.isAfter(dueAt)
          ? SlaStatus.breachedResolved
          : SlaStatus.met;
    }
    if (!now.isBefore(dueAt)) return SlaStatus.breached;
    final total = dueAt.difference(createdAt).inMilliseconds;
    final elapsed = now.difference(createdAt).inMilliseconds;
    return total > 0 && elapsed / total >= 0.75
        ? SlaStatus.atRisk
        : SlaStatus.onTrack;
  }
}
