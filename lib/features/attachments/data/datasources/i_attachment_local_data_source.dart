import '../dtos/ticket_attachment_dto.dart';

abstract interface class IAttachmentLocalDataSource {
  Future<List<TicketAttachmentDto>> getAttachmentsByTicketId(int ticketId);

  Future<int> insertAttachment(TicketAttachmentDto dto);

  Future<void> deleteAttachment(int id);
}
