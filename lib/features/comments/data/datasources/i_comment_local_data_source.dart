import '../dtos/ticket_comment_dto.dart';

abstract interface class ICommentLocalDataSource {
  Future<List<TicketCommentDto>> getCommentsByTicketId(int ticketId);

  Future<int> insertComment(TicketCommentDto dto);

  Future<void> updateComment(TicketCommentDto dto);

  Future<void> deleteComment(int id);
}
