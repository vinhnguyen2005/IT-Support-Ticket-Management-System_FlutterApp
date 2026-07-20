import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/features/comments/data/datasources/i_comment_local_data_source.dart';
import 'package:it_ticket_support_management/features/comments/data/dtos/ticket_comment_dto.dart';
import 'package:it_ticket_support_management/features/comments/data/mappers/comment_mapper.dart';
import 'package:it_ticket_support_management/features/comments/data/repositories/comment_repository_impl.dart';

void main() {
  test(
    'addComment returns the author name from the persisted joined row',
    () async {
      final dataSource = _CommentDataSourceFake();
      final repository = CommentRepositoryImpl(
        localDataSource: dataSource,
        mapper: const CommentMapper(),
      );

      final comment = await repository.addComment(
        ticketId: 10,
        authorId: 7,
        content: 'Status update',
      );

      expect(comment.id, 1);
      expect(comment.authorId, 7);
      expect(comment.authorName, 'Demo Employee');
      expect(comment.content, 'Status update');
    },
  );
}

class _CommentDataSourceFake implements ICommentLocalDataSource {
  TicketCommentDto? _comment;

  @override
  Future<int> insertComment(TicketCommentDto dto) async {
    _comment = TicketCommentDto(
      id: 1,
      ticketId: dto.ticketId,
      authorId: dto.authorId,
      authorName: 'Demo Employee',
      content: dto.content,
      createdAt: dto.createdAt,
    );
    return 1;
  }

  @override
  Future<List<TicketCommentDto>> getCommentsByTicketId(int ticketId) async {
    final comment = _comment;
    return comment == null ? [] : [comment];
  }

  @override
  Future<void> updateComment(TicketCommentDto dto) async {}

  @override
  Future<void> deleteComment(int id) async {}
}
