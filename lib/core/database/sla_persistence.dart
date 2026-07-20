import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

class SlaPersistence {
  const SlaPersistence._();

  static Future<void> refreshBreaches(Database database) async {
    final now = DateTime.now().toIso8601String();
    await database.transaction((transaction) async {
      await transaction.rawInsert(
        '''
        INSERT INTO ${AppDatabase.slaEventsTable} (
          ticketId, eventType, newDueAt, createdAt
        )
        SELECT id, 'Breached', resolutionDueAt, ?
        FROM ${AppDatabase.ticketsTable} t
        WHERE t.slaBreachedAt IS NULL
          AND t.slaCompletedAt IS NULL
          AND t.slaExceptionReason IS NULL
          AND LOWER(t.status) <> 'cancelled'
          AND t.resolutionDueAt IS NOT NULL
          AND julianday(t.resolutionDueAt) <= julianday(?)
      ''',
        [now, now],
      );
      await transaction.update(
        AppDatabase.ticketsTable,
        {'slaBreachedAt': now},
        where: '''
          slaBreachedAt IS NULL
          AND slaCompletedAt IS NULL
          AND slaExceptionReason IS NULL
          AND LOWER(status) <> 'cancelled'
          AND resolutionDueAt IS NOT NULL
          AND julianday(resolutionDueAt) <= julianday(?)
        ''',
        whereArgs: [now],
      );

      await transaction.rawInsert(
        '''
        INSERT INTO ${AppDatabase.slaEventsTable} (
          ticketId, eventType, newDueAt, createdAt
        )
        SELECT id, 'ResponseBreached', responseDueAt, ?
        FROM ${AppDatabase.ticketsTable} t
        WHERE t.firstRespondedAt IS NULL
          AND t.slaExceptionReason IS NULL
          AND LOWER(t.status) <> 'cancelled'
          AND t.responseDueAt IS NOT NULL
          AND julianday(t.responseDueAt) <= julianday(?)
          AND NOT EXISTS (
            SELECT 1 FROM ${AppDatabase.slaEventsTable} e
            WHERE e.ticketId = t.id AND e.eventType = 'ResponseBreached'
          )
      ''',
        [now, now],
      );
    });
  }
}
