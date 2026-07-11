import '../../domain/entities/ticket_comment.dart';
import '../dtos/ticket_comment_dto.dart';

class CommentMapper {
  const CommentMapper();

  TicketComment mapToEntity(TicketCommentDto dto) {
    return TicketComment(
      id: dto.id,
      ticketId: dto.ticketId,
      authorId: dto.authorId,
      authorName: dto.authorName,
      content: dto.content,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }
}
