class TicketComment {
  const TicketComment({
    this.id,
    required this.ticketId,
    required this.authorId,
    this.authorName,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int ticketId;
  final int authorId;
  final String? authorName;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
