import '../entities/ticket_attachment.dart';

abstract interface class IAttachmentRepository {
  Future<List<TicketAttachment>> getAttachmentsByTicketId(int ticketId);

  Future<TicketAttachment> addAttachment({
    required int ticketId,
    required int uploadedByUserId,
    required String fileName,
    required String filePath,
    String? contentType,
    int? fileSizeBytes,
  });

  Future<void> deleteAttachment(int id);
}
