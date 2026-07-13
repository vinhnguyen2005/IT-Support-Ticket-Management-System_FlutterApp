import '../dtos/ticket_dto.dart';
import '../dtos/update_ticket_status_dto.dart';

abstract interface class ITicketLocalDataSource {
  Future<int> insertTicket(TicketDto ticket);

  Future<List<TicketDto>> getTickets();

  Future<List<TicketDto>> getTicketsByRequester(int requesterId);

  Future<List<TicketDto>> getTicketsByAssignee(int assigneeId);

  Future<TicketDto?> getTicketById(int id);

  Future<List<UpdateTicketStatusDto>> getStatusNotesByTicketId(int ticketId);

  Future<int> updateTicket(TicketDto ticket);

  Future<void> updateTicketStatus(UpdateTicketStatusDto statusUpdate);

  Future<int> deleteTicket(int id);
}
