const _unsetFeedbackField = Object();

class Feedback {
  const Feedback({
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

  bool get hasValidRatings =>
      staffRating >= 1 &&
      staffRating <= 5 &&
      supportRating >= 1 &&
      supportRating <= 5;

  Feedback copyWith({
    int? id,
    int? ticketId,
    int? reviewerUserId,
    int? revieweeUserId,
    int? staffRating,
    int? supportRating,
    Object? comment = _unsetFeedbackField,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ticketTitle,
    String? reviewerName,
    String? revieweeName,
  }) => Feedback(
    id: id ?? this.id,
    ticketId: ticketId ?? this.ticketId,
    reviewerUserId: reviewerUserId ?? this.reviewerUserId,
    revieweeUserId: revieweeUserId ?? this.revieweeUserId,
    staffRating: staffRating ?? this.staffRating,
    supportRating: supportRating ?? this.supportRating,
    comment: identical(comment, _unsetFeedbackField)
        ? this.comment
        : comment as String?,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    ticketTitle: ticketTitle ?? this.ticketTitle,
    reviewerName: reviewerName ?? this.reviewerName,
    revieweeName: revieweeName ?? this.revieweeName,
  );
}
