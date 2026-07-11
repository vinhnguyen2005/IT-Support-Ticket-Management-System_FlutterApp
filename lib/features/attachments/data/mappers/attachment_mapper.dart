import '../../domain/entities/ticket_attachment.dart';
import '../dtos/ticket_attachment_dto.dart';

class AttachmentMapper {
  const AttachmentMapper();

  TicketAttachment mapToEntity(TicketAttachmentDto dto) {
    return TicketAttachment(
      id: dto.id,
      ticketId: dto.ticketId,
      uploadedByUserId: dto.uploadedByUserId,
      fileName: dto.fileName,
      filePath: dto.filePath,
      contentType: dto.contentType,
      fileSizeBytes: dto.fileSizeBytes,
      createdAt: dto.createdAt,
      uploaderName: dto.uploaderName,
    );
  }
}
