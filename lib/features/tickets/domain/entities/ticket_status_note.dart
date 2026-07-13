class TicketStatusNote {
  const TicketStatusNote({
    this.fromStatus,
    required this.toStatus,
    this.changedByUserId,
    this.note,
    required this.changedAt,
  });

  final String? fromStatus;
  final String toStatus;
  final int? changedByUserId;
  final String? note;
  final DateTime changedAt;
}
