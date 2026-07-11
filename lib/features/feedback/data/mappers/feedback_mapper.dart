import '../../domain/entities/feedback.dart';
import '../dtos/feedback_dto.dart';

class FeedbackMapper {
  const FeedbackMapper();

  Feedback mapToEntity(FeedbackDto dto) {
    return Feedback(
      id: dto.id,
      ticketId: dto.ticketId,
      userId: dto.userId,
      rating: dto.rating.clamp(1, 5),
      comment: dto.comment,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      ticketTitle: dto.ticketTitle,
      userName: dto.userName,
    );
  }

  FeedbackDto mapToDto(Feedback feedback) {
    return FeedbackDto(
      id: feedback.id,
      ticketId: feedback.ticketId,
      userId: feedback.userId,
      rating: feedback.rating.clamp(1, 5),
      comment: feedback.comment,
      createdAt: feedback.createdAt,
      updatedAt: feedback.updatedAt,
      ticketTitle: feedback.ticketTitle,
      userName: feedback.userName,
    );
  }
}
