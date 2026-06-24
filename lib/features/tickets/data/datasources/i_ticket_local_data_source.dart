import '../dtos/ticket_dto.dart';

abstract interface class ITicketLocalDataSource {
  Future<int> insertTicket(TicketDto ticket);

  Future<List<TicketDto>> getTickets();

  Future<TicketDto?> getTicketById(int id);

  Future<int> updateTicket(TicketDto ticket);

  Future<int> deleteTicket(int id);
}
