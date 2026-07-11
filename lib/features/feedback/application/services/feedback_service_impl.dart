import '../../domain/entities/feedback.dart';
import '../../domain/repositories/i_feedback_repository.dart';
import 'i_feedback_service.dart';

class FeedbackServiceImpl implements IFeedbackService {
  const FeedbackServiceImpl(this._repository);

  final IFeedbackRepository _repository;

  @override
  Future<Feedback?> getFeedbackByTicketId(int ticketId) {
    return _repository.getFeedbackByTicketId(ticketId);
  }

  @override
  Future<List<Feedback>> getFeedbackByUserId(int userId) {
    return _repository.getFeedbackByUserId(userId);
  }

  @override
  Future<Feedback> submitFeedback({
    required int ticketId,
    required int userId,
    required int rating,
    String? comment,
  }) async {
    // Validate rating
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be between 1 and 5');
    }

    return _repository.submitFeedback(
      ticketId: ticketId,
      userId: userId,
      rating: rating,
      comment: comment,
    );
  }

  @override
  Future<void> updateFeedback(Feedback feedback) async {
    if (!feedback.isValidRating) {
      throw ArgumentError('Rating must be between 1 and 5');
    }

    await _repository.updateFeedback(feedback);
  }

  @override
  Future<void> deleteFeedback(int id) {
    return _repository.deleteFeedback(id);
  }
}
