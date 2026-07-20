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
    final rows = await _database.rawQuery(
      '''
      SELECT f.*, t.title AS ticketTitle,
        reviewer.fullName AS reviewerName,
        reviewee.fullName AS revieweeName
      FROM ${AppDatabase.feedbackTable} f
      INNER JOIN ${AppDatabase.ticketsTable} t ON t.id = f.ticketId
      INNER JOIN ${AppDatabase.usersTable} reviewer
        ON reviewer.id = f.reviewerUserId
      INNER JOIN ${AppDatabase.usersTable} reviewee
        ON reviewee.id = f.revieweeUserId
      WHERE f.ticketId = ?
      LIMIT 1
      ''',
      [ticketId],
    );

    if (rows.isEmpty) {
      return null;
    }

    return FeedbackDto.fromMap(rows.first);
  }

  @override
  Future<List<FeedbackDto>> getFeedbackByReviewerUserId(
    int reviewerUserId,
  ) async {
    final rows = await _database.rawQuery(
      '''
      SELECT f.*, t.title AS ticketTitle,
        reviewer.fullName AS reviewerName,
        reviewee.fullName AS revieweeName
      FROM ${AppDatabase.feedbackTable} f
      INNER JOIN ${AppDatabase.ticketsTable} t ON t.id = f.ticketId
      INNER JOIN ${AppDatabase.usersTable} reviewer
        ON reviewer.id = f.reviewerUserId
      INNER JOIN ${AppDatabase.usersTable} reviewee
        ON reviewee.id = f.revieweeUserId
      WHERE f.reviewerUserId = ?
      ORDER BY f.createdAt DESC
      ''',
      [reviewerUserId],
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
    if (dto.id == null) {
      throw const AppException('Feedback id is required.');
    }
    final count = await _database.update(
      AppDatabase.feedbackTable,
      {
        'staffRating': dto.staffRating,
        'supportRating': dto.supportRating,
        'comment': dto.comment,
        'updatedAt': dto.updatedAt?.toIso8601String(),
      },
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
