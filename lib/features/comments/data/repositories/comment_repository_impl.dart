import '../../domain/entities/ticket_comment.dart';
import '../../domain/repositories/i_comment_repository.dart';
import '../datasources/i_comment_local_data_source.dart';
import '../dtos/ticket_comment_dto.dart';
import '../mappers/comment_mapper.dart';

class CommentRepositoryImpl implements ICommentRepository {
  const CommentRepositoryImpl({
    required ICommentLocalDataSource localDataSource,
    required CommentMapper mapper,
  })  : _localDataSource = localDataSource,
        _mapper = mapper;

  final ICommentLocalDataSource _localDataSource;
  final CommentMapper _mapper;

  @override
  Future<List<TicketComment>> getCommentsByTicketId(int ticketId) async {
    final dtos = await _localDataSource.getCommentsByTicketId(ticketId);
    return dtos.map(_mapper.mapToEntity).toList();
  }

  @override
  Future<TicketComment> addComment({
    required int ticketId,
    required int authorId,
    required String content,
  }) async {
    final now = DateTime.now();
    final id = await _localDataSource.insertComment(
      TicketCommentDto(
        ticketId: ticketId,
        authorId: authorId,
        content: content,
        createdAt: now,
      ),
    );

    return TicketComment(
      id: id,
      ticketId: ticketId,
      authorId: authorId,
      content: content,
      createdAt: now,
    );
  }

  @override
  Future<void> updateComment(TicketComment comment) async {
    await _localDataSource.updateComment(
      TicketCommentDto(
        id: comment.id,
        ticketId: comment.ticketId,
        authorId: comment.authorId,
        authorName: comment.authorName,
        content: comment.content,
        createdAt: comment.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteComment(int id) {
    return _localDataSource.deleteComment(id);
  }
}
