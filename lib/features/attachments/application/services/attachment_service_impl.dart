import '../../domain/entities/ticket_attachment.dart';
import '../../domain/repositories/i_attachment_repository.dart';
import 'i_attachment_service.dart';

class AttachmentServiceImpl implements IAttachmentService {
  const AttachmentServiceImpl(this._repository);

  final IAttachmentRepository _repository;

  @override
  Future<List<TicketAttachment>> getAttachmentsByTicketId(int ticketId) {
    return _repository.getAttachmentsByTicketId(ticketId);
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
    if (fileName.isEmpty) {
      throw ArgumentError('File name cannot be empty');
    }

    if (filePath.isEmpty) {
      throw ArgumentError('File path cannot be empty');
    }

    return _repository.addAttachment(
      ticketId: ticketId,
      uploadedByUserId: uploadedByUserId,
      fileName: fileName,
      filePath: filePath,
      contentType: contentType,
      fileSizeBytes: fileSizeBytes,
    );
  }

  @override
  Future<void> deleteAttachment(int id) {
    return _repository.deleteAttachment(id);
  }
}
