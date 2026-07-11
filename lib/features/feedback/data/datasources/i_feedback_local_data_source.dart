import '../dtos/feedback_dto.dart';

abstract interface class IFeedbackLocalDataSource {
  Future<FeedbackDto?> getFeedbackByTicketId(int ticketId);

  Future<List<FeedbackDto>> getFeedbackByUserId(int userId);

  Future<int> insertFeedback(FeedbackDto dto);

  Future<void> updateFeedback(FeedbackDto dto);

  Future<void> deleteFeedback(int id);
}
