import '../../domain/entities/ticket_comment.dart';
import '../../domain/repositories/i_comment_repository.dart';
import 'i_comment_service.dart';

class CommentServiceImpl implements ICommentService {
  const CommentServiceImpl(this._repository);

  final ICommentRepository _repository;

  @override
  Future<List<TicketComment>> getCommentsByTicketId(int ticketId) {
    return _repository.getCommentsByTicketId(ticketId);
  }

  @override
  Future<TicketComment> addComment({
    required int ticketId,
    required int authorId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Comment content cannot be empty');
    }

    return _repository.addComment(
      ticketId: ticketId,
      authorId: authorId,
      content: trimmed,
    );
  }

  @override
  Future<void> updateComment(TicketComment comment) async {
    final trimmed = comment.content.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Comment content cannot be empty');
    }

    await _repository.updateComment(comment);
  }

  @override
  Future<void> deleteComment(int id) {
    return _repository.deleteComment(id);
  }
}
