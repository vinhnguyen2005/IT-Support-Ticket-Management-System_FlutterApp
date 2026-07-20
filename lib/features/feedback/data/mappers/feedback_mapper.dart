import '../../domain/entities/feedback.dart';
import '../dtos/feedback_dto.dart';

class FeedbackMapper {
  const FeedbackMapper();

  Feedback mapToEntity(FeedbackDto dto) {
    return Feedback(
      id: dto.id,
      ticketId: dto.ticketId,
      reviewerUserId: dto.reviewerUserId,
      revieweeUserId: dto.revieweeUserId,
      staffRating: dto.staffRating,
      supportRating: dto.supportRating,
      comment: dto.comment,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      ticketTitle: dto.ticketTitle,
      reviewerName: dto.reviewerName,
      revieweeName: dto.revieweeName,
    );
  }

  FeedbackDto mapToDto(Feedback feedback) {
    return FeedbackDto(
      id: feedback.id,
      ticketId: feedback.ticketId,
      reviewerUserId: feedback.reviewerUserId,
      revieweeUserId: feedback.revieweeUserId,
      staffRating: feedback.staffRating,
      supportRating: feedback.supportRating,
      comment: feedback.comment,
      createdAt: feedback.createdAt,
      updatedAt: feedback.updatedAt,
      ticketTitle: feedback.ticketTitle,
      reviewerName: feedback.reviewerName,
      revieweeName: feedback.revieweeName,
    );
  }
}
