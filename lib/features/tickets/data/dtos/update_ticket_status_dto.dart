class UpdateTicketStatusDto {
  UpdateTicketStatusDto({
    required this.ticketId,
    required this.newStatus,
    this.oldStatus,
    this.changedByUserId,
    this.note,
    DateTime? changedAt,
  }) : changedAt = changedAt ?? DateTime.now();

  final int ticketId;
  final String? oldStatus;
  final String newStatus;
  final int? changedByUserId;
  final String? note;
  final DateTime changedAt;

  factory UpdateTicketStatusDto.fromMap(Map<String, Object?> map) {
    return UpdateTicketStatusDto(
      ticketId: map['ticketId'] as int,
      oldStatus: map['fromStatus'] as String?,
      newStatus: (map['toStatus'] as String?) ?? 'Open',
      changedByUserId: map['changedByUserId'] as int?,
      note: map['note'] as String?,
      changedAt: map['changedAt'] == null
          ? null
          : DateTime.parse(map['changedAt'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'ticketId': ticketId,
      'fromStatus': oldStatus,
      'toStatus': newStatus,
      'changedByUserId': changedByUserId,
      'note': note,
      'changedAt': changedAt.toIso8601String(),
    };
  }
}
