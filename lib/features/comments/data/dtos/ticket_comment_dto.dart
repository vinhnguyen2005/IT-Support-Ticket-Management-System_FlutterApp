class TicketCommentDto {
  const TicketCommentDto({
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

  factory TicketCommentDto.fromMap(Map<String, Object?> map) {
    return TicketCommentDto(
      id: _readInt(map['id']),
      ticketId: _readInt(map['ticketId']) ?? 0,
      authorId: _readInt(map['authorId']) ?? 0,
      authorName: map['authorName'] as String?,
      content: (map['content'] as String?) ?? '',
      createdAt: _readDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'authorId': authorId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
