class FeedbackSummaryReportDto {
  const FeedbackSummaryReportDto({
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

  factory FeedbackSummaryReportDto.fromMap(Map<String, Object?> map) {
    int readInt(String key) => (map[key] as num?)?.toInt() ?? 0;
    return FeedbackSummaryReportDto(
      closedTickets: readInt('closed_tickets'),
      totalFeedback: readInt('total_feedback'),
      averageRating: (map['average_rating'] as num?)?.toDouble() ?? 0,
      lowRatingCount: readInt('low_rating_count'),
      rating1Count: readInt('rating_1_count'),
      rating2Count: readInt('rating_2_count'),
      rating3Count: readInt('rating_3_count'),
      rating4Count: readInt('rating_4_count'),
      rating5Count: readInt('rating_5_count'),
    );
  }
}
