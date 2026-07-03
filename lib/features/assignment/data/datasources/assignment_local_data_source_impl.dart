import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/enums/ticket_status.dart';
import '../../../../core/errors/exceptions.dart';
import '../dtos/assignment_dto.dart';
import '../dtos/progress_update_dto.dart';
import 'i_assignment_local_data_source.dart';

class AssignmentLocalDataSourceImpl implements IAssignmentLocalDataSource {
  const AssignmentLocalDataSourceImpl(this._database);

  final Database _database;

  @override
  Future<List<AssignmentDto>> getAssignmentsForStaff(int staffId) async {
    final rows = await _database.rawQuery(
      '''
      SELECT
        a.id,
        a.ticketId,
        a.staffId,
        a.assignedByUserId,
        a.assignedAt,
        a.note,
        a.isActive,
        a.createdAt,
        a.updatedAt,
        t.title AS ticketTitle,
        t.description AS ticketDescription,
        t.issueType AS issueType,
        t.priority AS priority,
        t.status AS status,
        t.createdAt AS ticketCreatedAt,
        t.updatedAt AS ticketUpdatedAt,
        pu.message AS lastProgressMessage
      FROM ${AppDatabase.ticketAssignmentsTable} a
      INNER JOIN ${AppDatabase.ticketsTable} t ON t.id = a.ticketId
      LEFT JOIN ${AppDatabase.progressUpdatesTable} pu ON pu.id = (
        SELECT latest.id
        FROM ${AppDatabase.progressUpdatesTable} latest
        WHERE latest.ticketId = a.ticketId
        ORDER BY latest.createdAt DESC
        LIMIT 1
      )
      WHERE a.staffId = ? AND a.isActive = 1
      ORDER BY
        CASE LOWER(t.priority)
          WHEN 'critical' THEN 1
          WHEN 'high' THEN 2
          WHEN 'medium' THEN 3
          WHEN 'low' THEN 4
          ELSE 5
        END,
        t.createdAt ASC
      ''',
      [staffId],
    );

    return rows.map(AssignmentDto.fromMap).toList();
  }

  @override
  Future<AssignmentDto?> getAssignmentByTicket({
    required int ticketId,
    required int staffId,
  }) async {
    final rows = await _database.rawQuery(
      '''
      SELECT
        a.id,
        a.ticketId,
        a.staffId,
        a.assignedByUserId,
        a.assignedAt,
        a.note,
        a.isActive,
        a.createdAt,
        a.updatedAt,
        t.title AS ticketTitle,
        t.description AS ticketDescription,
        t.issueType AS issueType,
        t.priority AS priority,
        t.status AS status,
        t.createdAt AS ticketCreatedAt,
        t.updatedAt AS ticketUpdatedAt,
        pu.message AS lastProgressMessage
      FROM ${AppDatabase.ticketAssignmentsTable} a
      INNER JOIN ${AppDatabase.ticketsTable} t ON t.id = a.ticketId
      LEFT JOIN ${AppDatabase.progressUpdatesTable} pu ON pu.id = (
        SELECT latest.id
        FROM ${AppDatabase.progressUpdatesTable} latest
        WHERE latest.ticketId = a.ticketId
        ORDER BY latest.createdAt DESC
        LIMIT 1
      )
      WHERE a.ticketId = ? AND a.staffId = ? AND a.isActive = 1
      LIMIT 1
      ''',
      [ticketId, staffId],
    );

    if (rows.isEmpty) {
      return null;
    }

    return AssignmentDto.fromMap(rows.first);
  }

  @override
  Future<List<ProgressUpdateDto>> getProgressUpdates(int ticketId) async {
    final rows = await _database.query(
      AppDatabase.progressUpdatesTable,
      where: 'ticketId = ?',
      whereArgs: [ticketId],
      orderBy: 'createdAt DESC',
    );

    return rows.map(ProgressUpdateDto.fromMap).toList();
  }

  @override
  Future<void> assignTicket({
    required int ticketId,
    required int staffId,
    required int assignedByUserId,
    String? note,
  }) async {
    await _database.transaction((transaction) async {
      final ticketRows = await transaction.query(
        AppDatabase.ticketsTable,
        columns: ['id', 'status'],
        where: 'id = ?',
        whereArgs: [ticketId],
        limit: 1,
      );

      if (ticketRows.isEmpty) {
        throw const AppException('Ticket was not found.');
      }

      final previousStatus = ticketRows.first['status'] as String?;
      if (TicketStatus.tryParse(previousStatus ?? '') !=
          TicketStatus.submitted) {
        throw const AppException('Only Submitted tickets can be assigned.');
      }

      final staffRows = await transaction.query(
        AppDatabase.usersTable,
        columns: ['id'],
        where: 'id = ? AND LOWER(role) = ? AND isActive = 1',
        whereArgs: [staffId, 'staff'],
        limit: 1,
      );

      if (staffRows.isEmpty) {
        throw const AppException('Selected staff account is not active.');
      }

      final now = DateTime.now().toIso8601String();
      await transaction.update(
        AppDatabase.ticketAssignmentsTable,
        {'isActive': 0, 'updatedAt': now},
        where: 'ticketId = ? AND isActive = 1',
        whereArgs: [ticketId],
      );

      await transaction.insert(AppDatabase.ticketAssignmentsTable, {
        'ticketId': ticketId,
        'staffId': staffId,
        'assignedByUserId': assignedByUserId,
        'assignedAt': now,
        'note': note,
        'isActive': 1,
        'createdAt': now,
      });

      await transaction.update(
        AppDatabase.ticketsTable,
        {
          'assignedStaffId': staffId,
          'status': TicketStatus.assigned.value,
          'updatedAt': now,
        },
        where: 'id = ?',
        whereArgs: [ticketId],
      );

      await transaction.insert(AppDatabase.ticketStatusHistoriesTable, {
        'ticketId': ticketId,
        'changedByUserId': assignedByUserId,
        'fromStatus': previousStatus,
        'toStatus': TicketStatus.assigned.value,
        'note': note ?? 'Ticket assigned',
        'changedAt': now,
      });
    });
  }

  @override
  Future<int> addProgressUpdate(ProgressUpdateDto update) {
    return _database.insert(
      AppDatabase.progressUpdatesTable,
      update.toMap()..remove('id'),
    );
  }

  @override
  Future<void> updateTicketStatus({
    required int ticketId,
    required int staffId,
    required String status,
    String? note,
    String? solutionSummary,
  }) async {
    await _database.transaction((transaction) async {
      final assignmentRows = await transaction.query(
        AppDatabase.ticketAssignmentsTable,
        columns: ['id'],
        where: 'ticketId = ? AND staffId = ? AND isActive = 1',
        whereArgs: [ticketId, staffId],
        limit: 1,
      );

      if (assignmentRows.isEmpty) {
        throw const AppException('Assigned ticket was not found.');
      }

      final ticketRows = await transaction.query(
        AppDatabase.ticketsTable,
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [ticketId],
        limit: 1,
      );

      if (ticketRows.isEmpty) {
        throw const AppException('Ticket was not found.');
      }

      final previousStatus = ticketRows.first['status'] as String?;
      final now = DateTime.now().toIso8601String();
      final parsedStatus = TicketStatus.tryParse(status);
      if (parsedStatus == null) {
        throw AppException('Unsupported ticket status: $status.');
      }

      await transaction.update(
        AppDatabase.ticketsTable,
        {
          'status': parsedStatus.value,
          'updatedAt': now,
          if (parsedStatus == TicketStatus.resolved) 'resolvedAt': now,
          if (parsedStatus == TicketStatus.resolved)
            'solutionSummary': solutionSummary,
          if (parsedStatus == TicketStatus.closed) 'closedAt': now,
          if (parsedStatus != TicketStatus.closed) 'closedAt': null,
        },
        where: 'id = ?',
        whereArgs: [ticketId],
      );

      await transaction.insert(AppDatabase.ticketStatusHistoriesTable, {
        'ticketId': ticketId,
        'changedByUserId': staffId,
        'fromStatus': previousStatus,
        'toStatus': parsedStatus.value,
        'note': note,
        'changedAt': now,
      });
    });
  }
}
