import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../dtos/ticket_dto.dart';
import 'i_ticket_local_data_source.dart';

class TicketLocalDataSourceImpl implements ITicketLocalDataSource {
  const TicketLocalDataSourceImpl(this._database);

  final Database _database;

  @override
  Future<int> insertTicket(TicketDto ticket) {
    return _database.insert(
      AppDatabase.ticketsTable,
      ticket.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
  Future<int> updateTicket(TicketDto ticket) {
    final id = ticket.id;
    if (id == null) {
      throw ArgumentError('Ticket id is required for update.');
    }

    return _database.update(
      AppDatabase.ticketsTable,
      ticket.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> deleteTicket(int id) {
    return _database.delete(
      AppDatabase.ticketsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
