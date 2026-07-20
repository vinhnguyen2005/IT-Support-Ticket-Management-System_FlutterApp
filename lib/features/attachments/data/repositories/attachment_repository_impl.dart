import '../../domain/entities/ticket_attachment.dart';
import '../../domain/repositories/i_attachment_repository.dart';
import '../datasources/i_attachment_local_data_source.dart';
import '../dtos/ticket_attachment_dto.dart';
import '../mappers/attachment_mapper.dart';

class AttachmentRepositoryImpl implements IAttachmentRepository {
  const AttachmentRepositoryImpl({
    required IAttachmentLocalDataSource localDataSource,
    required AttachmentMapper mapper,
  }) : _localDataSource = localDataSource,
       _mapper = mapper;

  final IAttachmentLocalDataSource _localDataSource;
  final AttachmentMapper _mapper;

  @override
  Future<List<TicketAttachment>> getAttachmentsByTicketId(int ticketId) async {
    final dtos = await _localDataSource.getAttachmentsByTicketId(ticketId);
    return dtos.map(_mapper.mapToEntity).toList();
  }

  @override
  Future<TicketAttachment> addAttachment({
    required int ticketId,
    required int uploadedByUserId,
    required String fileName,
    required String filePath,
    String? contentType,
    int? fileSizeBytes,
  }) async {
    final now = DateTime.now();
    final id = await _localDataSource.insertAttachment(
      TicketAttachmentDto(
        ticketId: ticketId,
        uploadedByUserId: uploadedByUserId,
        fileName: fileName,
        filePath: filePath,
        contentType: contentType,
        fileSizeBytes: fileSizeBytes,
        createdAt: now,
      ),
    );

    return TicketAttachment(
      id: id,
      ticketId: ticketId,
      uploadedByUserId: uploadedByUserId,
      fileName: fileName,
      filePath: filePath,
      contentType: contentType,
      fileSizeBytes: fileSizeBytes,
      createdAt: now,
    );
  }

  @override
  Future<void> deleteAttachment(int id) {
    return _localDataSource.deleteAttachment(id);
  }
}
