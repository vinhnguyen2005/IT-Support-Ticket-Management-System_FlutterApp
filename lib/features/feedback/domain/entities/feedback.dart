const _unsetFeedbackField = Object();

class Feedback {
  const Feedback({
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

  bool get isValidRating => rating >= 1 && rating <= 5;

  Feedback copyWith({
    int? id,
    int? ticketId,
    int? userId,
    int? rating,
    Object? comment = _unsetFeedbackField,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ticketTitle,
    String? userName,
  }) {
    return Feedback(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: identical(comment, _unsetFeedbackField)
          ? this.comment
          : comment as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ticketTitle: ticketTitle ?? this.ticketTitle,
      userName: userName ?? this.userName,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Feedback &&
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
}
