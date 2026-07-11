import '../../../../core/enums/issue_type.dart';
import '../../../../core/enums/priority_level.dart';
import '../../../../core/enums/ticket_status.dart';

class TicketDto {
  const TicketDto({
    this.id,
    this.title = '',
    this.description = '',
    this.issueType = IssueType.defaultValue,
    this.priority = PriorityLevel.defaultValue,
    this.status = TicketStatus.defaultValue,
    required this.createdAt,
    this.updatedAt,
    this.attachmentUrl,
    this.requestedId,
    this.assignedId,
    this.categoryId,
    this.solutionSummary,
    this.resolvedAt,
    this.createdByUserId,
    this.updatedByUserId,
    this.createdBy,
    this.updatedBy,
    this.isDeleted = false,
    this.priorityId,
    this.departmentId,
    this.closedAt,
    this.reopenedAt,
  });

  final int? id;
  final String title;
  final String description;
  final String issueType;
  final String priority;
  final String status;
  final String? attachmentUrl;
  final int? requestedId;
  final int? assignedId;
  final int? categoryId;
  final String? solutionSummary;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? createdByUserId;
  final int? updatedByUserId;
  final String? createdBy;
  final int? updatedBy;
  final bool isDeleted;
  final int? priorityId;
  final int? departmentId;
  final DateTime? closedAt;
  final DateTime? reopenedAt;

  factory TicketDto.fromMap(Map<String, Object?> map) {
    return TicketDto(
      id: _readInt(map['id']),
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      issueType: (map['issueType'] as String?) ?? IssueType.defaultValue,
      priority: (map['priority'] as String?) ?? PriorityLevel.defaultValue,
      status: (map['status'] as String?) ?? TicketStatus.defaultValue,
      attachmentUrl: map['attachmentUrl'] as String?,
      requestedId:
          _readInt(map['requestedId']) ?? _readInt(map['createdByUserId']),
      assignedId:
          _readInt(map['assignedId']) ?? _readInt(map['assignedStaffId']),
      categoryId: _readInt(map['categoryId']),
      solutionSummary: map['solutionSummary'] as String?,
      resolvedAt: _readDateTime(map['resolvedAt']),
      createdAt: _readDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDateTime(map['updatedAt']),
      createdByUserId:
          _readInt(map['createdByUserId']) ?? _readInt(map['requestedId']),
      updatedByUserId:
          _readInt(map['updatedByUserId']) ?? _readInt(map['updatedBy']),
      createdBy: map['createdBy'] as String?,
      updatedBy: _readInt(map['updatedBy']),
      isDeleted: _readBool(map['isDeleted']),
      priorityId: _readInt(map['priorityId']),
      departmentId: _readInt(map['departmentId']),
      closedAt: _readDateTime(map['closedAt']),
      reopenedAt: _readDateTime(map['reopenedAt']),
    );
  }

  factory TicketDto.fromJson(Map<String, Object?> map) {
    return TicketDto(
      id: _readInt(map['id']),
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      issueType: (map['issueType'] as String?) ?? IssueType.defaultValue,
      priority: (map['priority'] as String?) ?? PriorityLevel.defaultValue,
      status: (map['status'] as String?) ?? TicketStatus.defaultValue,
      attachmentUrl: map['attachmentUrl'] as String?,
      requestedId: _readInt(map['requestedId']),
      assignedId: _readInt(map['assignedId']),
      categoryId: _readInt(map['categoryId']),
      solutionSummary: map['solutionSummary'] as String?,
      resolvedAt: _readDateTime(map['resolvedAt']),
      createdAt: _readDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDateTime(map['updatedAt']),
      createdByUserId: _readInt(map['createdByUserId']),
      updatedByUserId: _readInt(map['updatedByUserId']),
      createdBy: map['createdBy'] as String?,
      updatedBy: _readInt(map['updatedBy']),
      isDeleted: _readBool(map['isDeleted']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'issueType': issueType,
      'priority': priority,
      'status': status,
      'attachmentUrl': attachmentUrl,
      'createdByUserId': createdByUserId,
      'assignedStaffId': assignedId,
      'categoryId': categoryId,
      'solutionSummary': solutionSummary,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'priorityId': priorityId,
      'departmentId': departmentId,
      'closedAt': closedAt?.toIso8601String(),
      'reopenedAt': reopenedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'issueType': issueType,
      'priority': priority,
      'status': status,
      'attachmentUrl': attachmentUrl,
      'requestedId': requestedId,
      'assignedId': assignedId,
      'categoryId': categoryId,
      'solutionSummary': solutionSummary,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdByUserId': createdByUserId,
      'updatedByUserId': updatedByUserId,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isDeleted': isDeleted,
    };
  }

  static int? _readInt(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static bool _readBool(Object? value) {
    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }

    return false;
  }
}
