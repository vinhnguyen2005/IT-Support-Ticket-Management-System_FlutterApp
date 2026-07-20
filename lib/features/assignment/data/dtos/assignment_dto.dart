class AssignmentDto {
  const AssignmentDto({
    this.id,
    required this.ticketId,
    required this.staffId,
    this.assignedByUserId,
    required this.assignedAt,
    this.note,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.ticketTitle,
    this.ticketDescription,
    this.issueType,
    this.priority,
    this.status,
    this.ticketCreatedAt,
    this.ticketUpdatedAt,
    this.lastProgressMessage,
    this.firstRespondedAt,
    this.responseDueAt,
    this.resolutionDueAt,
    this.slaCompletedAt,
    this.slaExceptionReason,
  });

  final int? id;
  final int ticketId;
  final int staffId;
  final int? assignedByUserId;
  final DateTime assignedAt;
  final String? note;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? ticketTitle;
  final String? ticketDescription;
  final String? issueType;
  final String? priority;
  final String? status;
  final DateTime? ticketCreatedAt;
  final DateTime? ticketUpdatedAt;
  final String? lastProgressMessage;
  final DateTime? firstRespondedAt;
  final DateTime? responseDueAt;
  final DateTime? resolutionDueAt;
  final DateTime? slaCompletedAt;
  final String? slaExceptionReason;

  factory AssignmentDto.fromMap(Map<String, Object?> map) {
    return AssignmentDto(
      id: map['id'] as int?,
      ticketId: map['ticketId'] as int,
      staffId: map['staffId'] as int,
      assignedByUserId: map['assignedByUserId'] as int?,
      assignedAt: DateTime.parse(map['assignedAt'] as String),
      note: map['note'] as String?,
      isActive: ((map['isActive'] as int?) ?? 1) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] == null
          ? null
          : DateTime.parse(map['updatedAt'] as String),
      ticketTitle: map['ticketTitle'] as String?,
      ticketDescription: map['ticketDescription'] as String?,
      issueType: map['issueType'] as String?,
      priority: map['priority'] as String?,
      status: map['status'] as String?,
      ticketCreatedAt: map['ticketCreatedAt'] == null
          ? null
          : DateTime.parse(map['ticketCreatedAt'] as String),
      ticketUpdatedAt: map['ticketUpdatedAt'] == null
          ? null
          : DateTime.parse(map['ticketUpdatedAt'] as String),
      lastProgressMessage: map['lastProgressMessage'] as String?,
      firstRespondedAt: _readDateTime(map['firstRespondedAt']),
      responseDueAt: _readDateTime(map['responseDueAt']),
      resolutionDueAt: _readDateTime(map['resolutionDueAt']),
      slaCompletedAt: _readDateTime(map['slaCompletedAt']),
      slaExceptionReason: map['slaExceptionReason'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'staffId': staffId,
      'assignedByUserId': assignedByUserId,
      'assignedAt': assignedAt.toIso8601String(),
      'note': note,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static DateTime? _readDateTime(Object? value) {
    return value is String ? DateTime.tryParse(value) : value as DateTime?;
  }
}
