import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../dtos/ticket_attachment_dto.dart';
import 'i_attachment_local_data_source.dart';

class AttachmentLocalDataSourceImpl implements IAttachmentLocalDataSource {
  const AttachmentLocalDataSourceImpl(this._database);

  final Database _database;

  @override
  Future<List<TicketAttachmentDto>> getAttachmentsByTicketId(int ticketId) async {
    final rows = await _database.rawQuery(
      '''
      SELECT
        a.id,
        a.ticketId,
        a.uploadedByUserId,
        a.fileName,
        a.filePath,
        a.contentType,
        a.fileSizeBytes,
        a.createdAt,
        u.fullName AS uploaderName
      FROM ${AppDatabase.ticketAttachmentsTable} a
      LEFT JOIN ${AppDatabase.usersTable} u ON u.id = a.uploadedByUserId
      WHERE a.ticketId = ?
      ORDER BY a.createdAt DESC
      ''',
      [ticketId],
    );

    return rows.map(TicketAttachmentDto.fromMap).toList();
  }

  @override
  Future<int> insertAttachment(TicketAttachmentDto dto) {
    return _database.insert(
      AppDatabase.ticketAttachmentsTable,
      dto.toMap()..remove('id'),
    );
  }

  @override
  Future<void> deleteAttachment(int id) async {
    final count = await _database.delete(
      AppDatabase.ticketAttachmentsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count == 0) {
      throw const AppException('Attachment not found.');
    }
  }
}
