import '../../domain/entities/ticket_comment.dart';

abstract interface class ICommentService {
  Future<List<TicketComment>> getCommentsByTicketId(int ticketId);

  Future<TicketComment> addComment({
    required int ticketId,
    required int authorId,
    required String content,
  });

  Future<void> updateComment(TicketComment comment);

  Future<void> deleteComment(int id);
}
