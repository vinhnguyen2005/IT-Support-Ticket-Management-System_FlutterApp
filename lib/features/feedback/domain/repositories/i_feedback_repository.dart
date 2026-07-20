import '../entities/feedback.dart';

abstract interface class IFeedbackRepository {
  Future<Feedback?> getFeedbackByTicketId(int ticketId);

  Future<List<Feedback>> getFeedbackByReviewerUserId(int reviewerUserId);

  Future<Feedback> submitFeedback({
    required int ticketId,
    required int reviewerUserId,
    required int revieweeUserId,
    required int staffRating,
    required int supportRating,
    String? comment,
  });

  Future<void> updateFeedback(Feedback feedback);

  Future<void> deleteFeedback(int id);
}
