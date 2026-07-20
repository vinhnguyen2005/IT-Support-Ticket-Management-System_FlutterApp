class LowRatingFeedbackReportDto {
  const LowRatingFeedbackReportDto({
    required this.feedbackId,
    required this.ticketId,
    required this.ticketTitle,
    required this.userName,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  final int feedbackId;
  final int ticketId;
  final String ticketTitle;
  final String userName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  factory LowRatingFeedbackReportDto.fromMap(Map<String, Object?> map) {
    return LowRatingFeedbackReportDto(
      feedbackId: map['feedback_id'] as int,
      ticketId: map['ticket_id'] as int,
      ticketTitle: map['ticket_title'] as String,
      userName: map['user_name'] as String,
      rating: map['rating'] as int,
      comment: map['comment'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
