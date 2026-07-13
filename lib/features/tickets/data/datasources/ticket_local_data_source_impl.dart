import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/enums/ticket_status.dart';
import '../../../../core/errors/exceptions.dart';
import '../dtos/ticket_dto.dart';
import '../dtos/update_ticket_status_dto.dart';
import 'i_ticket_local_data_source.dart';

class TicketLocalDataSourceImpl implements ITicketLocalDataSource {
  const TicketLocalDataSourceImpl(this._database);

  static const int _legacyGeneralSupportCategoryId = 4;
  static const String _generalSupportCategoryName = 'General Support';

  final Database _database;

  @override
  Future<int> insertTicket(TicketDto ticket) async {
    final categoryRouting = await _getCategoryRouting(ticket.categoryId);

    return _database.transaction((transaction) async {
      final id = await transaction.insert(
        AppDatabase.ticketsTable,
        _ticketInsertMap(ticket, categoryRouting),
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
  Future<List<UpdateTicketStatusDto>> getStatusNotesByTicketId(
    int ticketId,
  ) async {
    final rows = await _database.query(
      AppDatabase.ticketStatusHistoriesTable,
      where: 'ticketId = ?',
      whereArgs: [ticketId],
      orderBy: 'changedAt DESC',
    );

    return rows.map(UpdateTicketStatusDto.fromMap).toList();
  }

  @override
  Future<int> updateTicket(TicketDto ticket) async {
    final id = ticket.id;
    if (id == null) {
      throw ArgumentError('Ticket id is required for update.');
    }

    final categoryRouting = await _getCategoryRouting(ticket.categoryId);

    return _database.update(
      AppDatabase.ticketsTable,
      _ticketUpdateMap(ticket, categoryRouting),
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
      final newStatus = TicketStatus.tryParse(statusUpdate.newStatus);
      if (newStatus == null) {
        throw AppException(
          'Unsupported ticket status: ${statusUpdate.newStatus}.',
        );
      }

      await transaction.update(
        AppDatabase.ticketsTable,
        {
          'status': newStatus.value,
          'updatedAt': now,
          if (newStatus == TicketStatus.resolved) 'resolvedAt': now,
          if (newStatus == TicketStatus.resolved)
            'solutionSummary': statusUpdate.solutionSummary,
          if (newStatus == TicketStatus.closed) 'closedAt': now,
          if (newStatus != TicketStatus.closed) 'closedAt': null,
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

  Future<_CategoryRouting?> _getCategoryRouting(int? categoryId) async {
    if (categoryId == null) {
      return null;
    }

    final rows = await _database.query(
      AppDatabase.categoriesTable,
      columns: ['id', 'departmentId'],
      where: 'id = ? AND isActive = 1',
      whereArgs: [categoryId],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      return _CategoryRouting.fromMap(rows.first);
    }

    if (categoryId == _legacyGeneralSupportCategoryId) {
      final generalSupportRows = await _database.query(
        AppDatabase.categoriesTable,
        columns: ['id', 'departmentId'],
        where: 'name = ? AND isActive = 1',
        whereArgs: [_generalSupportCategoryName],
        limit: 1,
      );

      if (generalSupportRows.isNotEmpty) {
        return _CategoryRouting.fromMap(generalSupportRows.first);
      }
    }

    throw const AppException('Selected category is not available.');
  }

  Map<String, Object?> _ticketInsertMap(
    TicketDto ticket,
    _CategoryRouting? categoryRouting,
  ) {
    final map = ticket.toMap()..remove('id');
    map['categoryId'] = categoryRouting?.categoryId ?? ticket.categoryId;
    map['departmentId'] = ticket.departmentId ?? categoryRouting?.departmentId;
    return map;
  }

  Map<String, Object?> _ticketUpdateMap(
    TicketDto ticket,
    _CategoryRouting? categoryRouting,
  ) {
    final map = ticket.toMap()
      ..remove('id')
      ..remove('createdAt');
    map['categoryId'] = categoryRouting?.categoryId ?? ticket.categoryId;
    map['departmentId'] = ticket.departmentId ?? categoryRouting?.departmentId;
    return map;
  }
}

class _CategoryRouting {
  const _CategoryRouting({required this.categoryId, this.departmentId});

  final int categoryId;
  final int? departmentId;

  factory _CategoryRouting.fromMap(Map<String, Object?> map) {
    return _CategoryRouting(
      categoryId: map['id'] as int,
      departmentId: map['departmentId'] as int?,
    );
  }
}
