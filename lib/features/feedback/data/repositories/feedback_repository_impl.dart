import '../../domain/entities/feedback.dart';
import '../../domain/repositories/i_feedback_repository.dart';
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
  Future<List<Feedback>> getFeedbackByUserId(int userId) async {
    final dtos = await _localDataSource.getFeedbackByUserId(userId);
    return dtos.map(_mapper.mapToEntity).toList();
  }

  @override
  Future<Feedback> submitFeedback({
    required int ticketId,
    required int userId,
    required int rating,
    String? comment,
  }) async {
    final now = DateTime.now();
    final existingFeedback = await _localDataSource.getFeedbackByTicketId(
      ticketId,
    );
    if (existingFeedback != null) {
      final updatedDto = FeedbackDto(
        id: existingFeedback.id,
        ticketId: existingFeedback.ticketId,
        userId: userId,
        rating: rating.clamp(1, 5),
        comment: comment,
        createdAt: existingFeedback.createdAt,
        updatedAt: now,
        ticketTitle: existingFeedback.ticketTitle,
        userName: existingFeedback.userName,
      );
      await _localDataSource.updateFeedback(updatedDto);
      return _mapper.mapToEntity(updatedDto);
    }

    final id = await _localDataSource.insertFeedback(
      FeedbackDto(
        ticketId: ticketId,
        userId: userId,
        rating: rating.clamp(1, 5),
        comment: comment,
        createdAt: now,
      ),
    );

    return Feedback(
      id: id,
      ticketId: ticketId,
      userId: userId,
      rating: rating.clamp(1, 5),
      comment: comment,
      createdAt: now,
    );
  }

  @override
  Future<void> updateFeedback(Feedback feedback) async {
    await _localDataSource.updateFeedback(
      _mapper
          .mapToDto(feedback)
          .copyWith(
            rating: feedback.rating.clamp(1, 5),
            updatedAt: DateTime.now(),
          ),
    );
  }

  @override
  Future<void> deleteFeedback(int id) {
    return _localDataSource.deleteFeedback(id);
  }
}
