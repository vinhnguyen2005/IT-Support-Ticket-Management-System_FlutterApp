import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../dtos/ticket_comment_dto.dart';
import 'i_comment_local_data_source.dart';

class CommentLocalDataSourceImpl implements ICommentLocalDataSource {
  const CommentLocalDataSourceImpl(this._database);

  final Database _database;

  @override
  Future<List<TicketCommentDto>> getCommentsByTicketId(int ticketId) async {
    final rows = await _database.rawQuery(
      '''
      SELECT
        c.id,
        c.ticketId,
        c.authorId,
        c.content,
        c.createdAt,
        c.updatedAt,
        u.fullName AS authorName
      FROM ${AppDatabase.ticketCommentsTable} c
      LEFT JOIN ${AppDatabase.usersTable} u ON u.id = c.authorId
      WHERE c.ticketId = ?
      ORDER BY c.createdAt ASC
      ''',
      [ticketId],
    );

    return rows.map(TicketCommentDto.fromMap).toList();
  }

  @override
  Future<int> insertComment(TicketCommentDto dto) {
    return _database.insert(
      AppDatabase.ticketCommentsTable,
      dto.toMap()..remove('id'),
    );
  }

  @override
  Future<void> updateComment(TicketCommentDto dto) async {
    final count = await _database.update(
      AppDatabase.ticketCommentsTable,
      dto.toMap(),
      where: 'id = ?',
      whereArgs: [dto.id],
    );

    if (count == 0) {
      throw const AppException('Comment not found.');
    }
  }

  @override
  Future<void> deleteComment(int id) async {
    final count = await _database.delete(
      AppDatabase.ticketCommentsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count == 0) {
      throw const AppException('Comment not found.');
    }
  }
}
