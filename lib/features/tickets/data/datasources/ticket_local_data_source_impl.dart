import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../dtos/ticket_dto.dart';
import '../dtos/update_ticket_status_dto.dart';
import 'i_ticket_local_data_source.dart';

class TicketLocalDataSourceImpl implements ITicketLocalDataSource {
  const TicketLocalDataSourceImpl(this._database);

  final Database _database;

  @override
  Future<int> insertTicket(TicketDto ticket) async {
    await _ensureCategoryIsUsable(ticket.categoryId);

    return _database.transaction((transaction) async {
      final id = await transaction.insert(
        AppDatabase.ticketsTable,
        _ticketInsertMap(ticket),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await transaction.insert(AppDatabase.ticketStatusHistoriesTable, {
        'ticketId': id,
        'changedByUserId': ticket.createdByUserId ?? ticket.requestedId,
        'fromStatus': null,
        'toStatus': ticket.status,
        'note': 'Ticket created',
        'changedAt': ticket.createdAt.toIso8601String(),
      });

      return id;
    });
  }

  @override
  Future<List<TicketDto>> getTickets() async {
    final rows = await _database.query(
      AppDatabase.ticketsTable,
      orderBy: 'createdAt DESC',
    );

    return rows.map(TicketDto.fromMap).toList();
  }

  @override
  Future<List<TicketDto>> getTicketsByRequester(int requesterId) async {
    final rows = await _database.query(
      AppDatabase.ticketsTable,
      where: 'createdByUserId = ?',
      whereArgs: [requesterId],
      orderBy: 'createdAt DESC',
    );

    return rows.map(TicketDto.fromMap).toList();
  }

  @override
  Future<List<TicketDto>> getTicketsByAssignee(int assigneeId) async {
    final rows = await _database.query(
      AppDatabase.ticketsTable,
      where: 'assignedStaffId = ?',
      whereArgs: [assigneeId],
      orderBy: 'createdAt DESC',
    );

    return rows.map(TicketDto.fromMap).toList();
  }

  @override
  Future<TicketDto?> getTicketById(int id) async {
    final rows = await _database.query(
      AppDatabase.ticketsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return TicketDto.fromMap(rows.first);
  }

  @override
  Future<int> updateTicket(TicketDto ticket) async {
    final id = ticket.id;
    if (id == null) {
      throw ArgumentError('Ticket id is required for update.');
    }

    await _ensureCategoryIsUsable(ticket.categoryId);

    return _database.update(
      AppDatabase.ticketsTable,
      _ticketUpdateMap(ticket),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateTicketStatus(UpdateTicketStatusDto statusUpdate) async {
    await _database.transaction((transaction) async {
      final rows = await transaction.query(
        AppDatabase.ticketsTable,
        columns: ['id', 'status'],
        where: 'id = ?',
        whereArgs: [statusUpdate.ticketId],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw const AppException('Ticket was not found.');
      }

      final previousStatus =
          statusUpdate.oldStatus ?? rows.first['status'] as String?;
      final now = statusUpdate.changedAt.toIso8601String();

      await transaction.update(
        AppDatabase.ticketsTable,
        {
          'status': statusUpdate.newStatus,
          'updatedAt': now,
          if (statusUpdate.newStatus.toLowerCase() == 'closed') 'closedAt': now,
          if (statusUpdate.newStatus.toLowerCase() != 'closed')
            'closedAt': null,
          if (statusUpdate.newStatus.toLowerCase() == 'reopened')
            'reopenedAt': now,
        },
        where: 'id = ?',
        whereArgs: [statusUpdate.ticketId],
      );

      await transaction.insert(
        AppDatabase.ticketStatusHistoriesTable,
        statusUpdate.toMap(),
      );

      if (previousStatus != statusUpdate.oldStatus) {
        await transaction.update(
          AppDatabase.ticketStatusHistoriesTable,
          {'fromStatus': previousStatus},
          where: 'ticketId = ? AND changedAt = ?',
          whereArgs: [statusUpdate.ticketId, now],
        );
      }
    });
  }

  @override
  Future<int> deleteTicket(int id) {
    return _database.delete(
      AppDatabase.ticketsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _ensureCategoryIsUsable(int? categoryId) async {
    if (categoryId == null) {
      return;
    }

    final rows = await _database.query(
      AppDatabase.categoriesTable,
      columns: ['id'],
      where: 'id = ? AND isActive = 1',
      whereArgs: [categoryId],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const AppException('Selected category is not available.');
    }
  }

  Map<String, Object?> _ticketInsertMap(TicketDto ticket) {
    return ticket.toMap()..remove('id');
  }

  Map<String, Object?> _ticketUpdateMap(TicketDto ticket) {
    return ticket.toMap()
      ..remove('id')
      ..remove('createdAt');
  }
}
