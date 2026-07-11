class FeedbackDto {
  const FeedbackDto({
    this.id,
    required this.ticketId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
    this.ticketTitle,
    this.userName,
  });

  final int? id;
  final int ticketId;
  final int userId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? ticketTitle;
  final String? userName;

  factory FeedbackDto.fromMap(Map<String, Object?> map) {
    return FeedbackDto(
      id: _readInt(map['id']),
      ticketId: _readInt(map['ticketId']) ?? 0,
      userId: _readInt(map['userId']) ?? 0,
      rating: _readInt(map['rating']) ?? 0,
      comment: map['comment'] as String?,
      createdAt: _readDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDateTime(map['updatedAt']),
      ticketTitle: map['ticketTitle'] as String?,
      userName: map['userName'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  FeedbackDto copyWith({
    int? id,
    int? ticketId,
    int? userId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ticketTitle,
    String? userName,
  }) {
    return FeedbackDto(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ticketTitle: ticketTitle ?? this.ticketTitle,
      userName: userName ?? this.userName,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FeedbackDto &&
            other.id == id &&
            other.ticketId == ticketId &&
            other.userId == userId &&
            other.rating == rating &&
            other.comment == comment &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt &&
            other.ticketTitle == ticketTitle &&
            other.userName == userName;
  }

  @override
  int get hashCode => Object.hash(
    id,
    ticketId,
    userId,
    rating,
    comment,
    createdAt,
    updatedAt,
    ticketTitle,
    userName,
  );

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
