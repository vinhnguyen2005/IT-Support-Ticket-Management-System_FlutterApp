import '../../domain/entities/feedback.dart';
import '../../domain/repositories/i_feedback_repository.dart';
import '../../../../core/errors/exceptions.dart';
import '../datasources/i_feedback_local_data_source.dart';
import '../dtos/feedback_dto.dart';
import '../mappers/feedback_mapper.dart';

class FeedbackRepositoryImpl implements IFeedbackRepository {
  const FeedbackRepositoryImpl({
    required IFeedbackLocalDataSource localDataSource,
    required FeedbackMapper mapper,
  }) : _localDataSource = localDataSource,
       _mapper = mapper;

  final IFeedbackLocalDataSource _localDataSource;
  final FeedbackMapper _mapper;

  @override
  Future<Feedback?> getFeedbackByTicketId(int ticketId) async {
    final dto = await _localDataSource.getFeedbackByTicketId(ticketId);
    return dto != null ? _mapper.mapToEntity(dto) : null;
  }

  @override
  Future<List<Feedback>> getFeedbackByReviewerUserId(int reviewerUserId) async {
    final dtos = await _localDataSource.getFeedbackByReviewerUserId(
      reviewerUserId,
    );
    return dtos.map(_mapper.mapToEntity).toList();
  }

  @override
  Future<Feedback> submitFeedback({
    required int ticketId,
    required int reviewerUserId,
    required int revieweeUserId,
    required int staffRating,
    required int supportRating,
    String? comment,
  }) async {
    final now = DateTime.now();
    final existingFeedback = await _localDataSource.getFeedbackByTicketId(
      ticketId,
    );
    if (existingFeedback != null) {
      throw const AppException(
        'Feedback already exists for this ticket. Please update it instead.',
      );
    }

    final id = await _localDataSource.insertFeedback(
      FeedbackDto(
        ticketId: ticketId,
        reviewerUserId: reviewerUserId,
        revieweeUserId: revieweeUserId,
        staffRating: staffRating,
        supportRating: supportRating,
        comment: comment,
        createdAt: now,
      ),
    );

    return Feedback(
      id: id,
      ticketId: ticketId,
      reviewerUserId: reviewerUserId,
      revieweeUserId: revieweeUserId,
      staffRating: staffRating,
      supportRating: supportRating,
      comment: comment,
      createdAt: now,
    );
  }

  @override
  Future<void> updateFeedback(Feedback feedback) async {
    await _localDataSource.updateFeedback(
      _mapper.mapToDto(feedback).copyWith(updatedAt: DateTime.now()),
    );
  }

  @override
  Future<void> deleteFeedback(int id) {
    return _localDataSource.deleteFeedback(id);
  }
}
