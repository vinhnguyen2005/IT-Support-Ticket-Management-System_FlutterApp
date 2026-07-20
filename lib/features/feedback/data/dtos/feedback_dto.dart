class FeedbackDto {
  const FeedbackDto({
    this.id,
    required this.ticketId,
    required this.reviewerUserId,
    required this.revieweeUserId,
    required this.staffRating,
    required this.supportRating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
    this.ticketTitle,
    this.reviewerName,
    this.revieweeName,
  });

  final int? id;
  final int ticketId;
  final int reviewerUserId;
  final int revieweeUserId;
  final int staffRating;
  final int supportRating;
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? ticketTitle;
  final String? reviewerName;
  final String? revieweeName;

  FeedbackDto copyWith({
    int? id,
    int? ticketId,
    int? reviewerUserId,
    int? revieweeUserId,
    int? staffRating,
    int? supportRating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ticketTitle,
    String? reviewerName,
    String? revieweeName,
  }) {
    return FeedbackDto(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      reviewerUserId: reviewerUserId ?? this.reviewerUserId,
      revieweeUserId: revieweeUserId ?? this.revieweeUserId,
      staffRating: staffRating ?? this.staffRating,
      supportRating: supportRating ?? this.supportRating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ticketTitle: ticketTitle ?? this.ticketTitle,
      reviewerName: reviewerName ?? this.reviewerName,
      revieweeName: revieweeName ?? this.revieweeName,
    );
  }

  factory FeedbackDto.fromMap(Map<String, Object?> map) => FeedbackDto(
    id: _readInt(map['id']),
    ticketId: _readInt(map['ticketId']) ?? 0,
    reviewerUserId: _readInt(map['reviewerUserId']) ?? 0,
    revieweeUserId: _readInt(map['revieweeUserId']) ?? 0,
    staffRating: _readInt(map['staffRating']) ?? 0,
    supportRating: _readInt(map['supportRating']) ?? 0,
    comment: map['comment'] as String?,
    createdAt: _readDateTime(map['createdAt']) ?? DateTime.now(),
    updatedAt: _readDateTime(map['updatedAt']),
    ticketTitle: map['ticketTitle'] as String?,
    reviewerName: map['reviewerName'] as String?,
    revieweeName: map['revieweeName'] as String?,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'ticketId': ticketId,
    'reviewerUserId': reviewerUserId,
    'revieweeUserId': revieweeUserId,
    'staffRating': staffRating,
    'supportRating': supportRating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static int? _readInt(Object? value) => value is int
      ? value
      : value is num
      ? value.toInt()
      : int.tryParse('$value');
  static DateTime? _readDateTime(Object? value) =>
      value is DateTime ? value : DateTime.tryParse('$value');
}
