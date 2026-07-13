import '../../../../core/enums/issue_type.dart';
import '../../../../core/enums/priority_level.dart';
import '../entities/ticket.dart';
import '../entities/ticket_status_note.dart';

abstract interface class ITicketRepository {
  Future<List<Ticket>> getTickets();

  Future<List<Ticket>> getTicketsByRequester(int requesterId);

  Future<List<Ticket>> getTicketsByAssignee(int assigneeId);

  Future<Ticket?> getTicketById(int id);

  Future<List<TicketStatusNote>> getStatusNotesByTicketId(int ticketId);

  Future<Ticket> createTicket({
    required String title,
    required String description,
    String issueType = IssueType.defaultValue,
    String priority = PriorityLevel.defaultValue,
    int? requesterId,
    int? categoryId,
    String? attachmentUrl,
  });

  Future<Ticket> updateTicket(Ticket ticket);

  Future<Ticket> updateTicketStatus({
    required int ticketId,
    required String status,
    int? changedByUserId,
    String? changedByRole,
    String? note,
    String? solutionSummary,
  });

  Future<void> deleteTicket(int id);
}
