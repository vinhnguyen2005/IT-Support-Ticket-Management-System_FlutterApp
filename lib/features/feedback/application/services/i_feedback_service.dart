import '../../domain/entities/feedback.dart';

abstract interface class IFeedbackService {
  Future<Feedback?> getFeedbackByTicketId(int ticketId);

  Future<List<Feedback>> getFeedbackByUserId(int userId);

  Future<Feedback> submitFeedback({
    required int ticketId,
    required int userId,
    required int rating,
    String? comment,
  });

  Future<void> updateFeedback(Feedback feedback);

  Future<void> deleteFeedback(int id);
}
