class LowRatingFeedbackReport {
  const LowRatingFeedbackReport({
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
}
