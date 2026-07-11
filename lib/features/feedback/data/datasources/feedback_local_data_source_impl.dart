import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../dtos/feedback_dto.dart';
import 'i_feedback_local_data_source.dart';

class FeedbackLocalDataSourceImpl implements IFeedbackLocalDataSource {
  const FeedbackLocalDataSourceImpl(this._database);

  final Database _database;

  @override
  Future<FeedbackDto?> getFeedbackByTicketId(int ticketId) async {
    final rows = await _database.query(
      AppDatabase.feedbackTable,
      where: 'ticketId = ?',
      whereArgs: [ticketId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return FeedbackDto.fromMap(rows.first);
  }

  @override
  Future<List<FeedbackDto>> getFeedbackByUserId(int userId) async {
    final rows = await _database.query(
      AppDatabase.feedbackTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return rows.map(FeedbackDto.fromMap).toList();
  }

  @override
  Future<int> insertFeedback(FeedbackDto dto) {
    return _database.insert(
      AppDatabase.feedbackTable,
      dto.toMap()..remove('id'),
    );
  }

  @override
  Future<void> updateFeedback(FeedbackDto dto) async {
    final count = await _database.update(
      AppDatabase.feedbackTable,
      dto.toMap(),
      where: 'id = ?',
      whereArgs: [dto.id],
    );

    if (count == 0) {
      throw const AppException('Feedback not found.');
    }
  }

  @override
  Future<void> deleteFeedback(int id) async {
    final count = await _database.delete(
      AppDatabase.feedbackTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count == 0) {
      throw const AppException('Feedback not found.');
    }
  }
}
