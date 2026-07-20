class FeedbackSummaryReport {
  const FeedbackSummaryReport({
    required this.closedTickets,
    required this.totalFeedback,
    required this.averageRating,
    required this.lowRatingCount,
    required this.rating1Count,
    required this.rating2Count,
    required this.rating3Count,
    required this.rating4Count,
    required this.rating5Count,
  });

  final int closedTickets;
  final int totalFeedback;
  final double averageRating;
  final int lowRatingCount;
  final int rating1Count;
  final int rating2Count;
  final int rating3Count;
  final int rating4Count;
  final int rating5Count;

  double get feedbackRate =>
      closedTickets == 0 ? 0 : totalFeedback / closedTickets;
}
