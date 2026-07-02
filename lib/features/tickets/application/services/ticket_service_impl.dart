import '../../../../core/enums/issue_type.dart';
import '../../../../core/enums/priority_level.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/i_ticket_repository.dart';
import 'i_ticket_service.dart';

class TicketServiceImpl implements ITicketService {
  const TicketServiceImpl(this._ticketRepository);

  final ITicketRepository _ticketRepository;

  @override
  Future<List<Ticket>> getTickets() {
    return _ticketRepository.getTickets();
  }

  @override
  Future<List<Ticket>> getTicketsByRequester(int requesterId) {
    _validateId(requesterId, 'Requester id is required.');
    return _ticketRepository.getTicketsByRequester(requesterId);
  }

  @override
  Future<List<Ticket>> getTicketsByAssignee(int assigneeId) {
    _validateId(assigneeId, 'Assignee id is required.');
    return _ticketRepository.getTicketsByAssignee(assigneeId);
  }

  @override
  Future<Ticket?> getTicketById(int id) {
    _validateId(id, 'Ticket id is required.');
    return _ticketRepository.getTicketById(id);
  }

  @override
  Future<Ticket> createTicket({
    required String title,
    required String description,
    String issueType = IssueType.defaultValue,
    String priority = PriorityLevel.defaultValue,
    int? requesterId,
    int? categoryId,
    String? attachmentUrl,
  }) {
    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();

    if (normalizedTitle.isEmpty) {
      throw const AppException('Ticket title is required.');
    }

    if (normalizedDescription.isEmpty) {
      throw const AppException('Ticket description is required.');
    }

    _validateOptionalId(requesterId, 'Requester id is invalid.');
    _validateOptionalId(categoryId, 'Category id is invalid.');

    return _ticketRepository.createTicket(
      title: normalizedTitle,
      description: normalizedDescription,
      issueType: _emptyToDefault(issueType, IssueType.defaultValue),
      priority: _emptyToDefault(priority, PriorityLevel.defaultValue),
      requesterId: requesterId,
      categoryId: categoryId,
      attachmentUrl: _emptyToNull(attachmentUrl),
    );
  }

  @override
  Future<Ticket> updateTicket(Ticket ticket) {
    final ticketId = ticket.id;
    if (ticketId == null || ticketId <= 0) {
      throw const AppException('Ticket id is required.');
    }

    if (ticket.title.trim().isEmpty) {
      throw const AppException('Ticket title is required.');
    }

    if (ticket.description.trim().isEmpty) {
      throw const AppException('Ticket description is required.');
    }

    return _ticketRepository.updateTicket(
      Ticket(
        id: ticket.id,
        title: ticket.title.trim(),
        description: ticket.description.trim(),
        status: ticket.status,
        priority: _emptyToDefault(ticket.priority, PriorityLevel.defaultValue),
        issueType: _emptyToDefault(ticket.issueType, IssueType.defaultValue),
        attachmentUrl: _emptyToNull(ticket.attachmentUrl),
        requestedId: ticket.requestedId,
        assignedId: ticket.assignedId,
        categoryId: ticket.categoryId,
        solutionSummary: _emptyToNull(ticket.solutionSummary),
        resolvedAt: ticket.resolvedAt,
        createdAt: ticket.createdAt,
        updatedAt: ticket.updatedAt,
        createdByUserId: ticket.createdByUserId,
        updatedByUserId: ticket.updatedByUserId,
        isDeleted: ticket.isDeleted,
      ),
    );
  }

  @override
  Future<Ticket> updateTicketStatus({
    required int ticketId,
    required String status,
    int? changedByUserId,
    String? note,
    String? solutionSummary,
  }) {
    _validateId(ticketId, 'Ticket id is required.');
    _validateOptionalId(changedByUserId, 'Changed-by user id is invalid.');

    final normalizedStatus = status.trim();
    if (normalizedStatus.isEmpty) {
      throw const AppException('Ticket status is required.');
    }

    return _ticketRepository.updateTicketStatus(
      ticketId: ticketId,
      status: normalizedStatus,
      changedByUserId: changedByUserId,
      note: _emptyToNull(note),
      solutionSummary: _emptyToNull(solutionSummary),
    );
  }

  @override
  Future<void> deleteTicket(int id) {
    _validateId(id, 'Ticket id is required.');
    return _ticketRepository.deleteTicket(id);
  }

  void _validateId(int id, String message) {
    if (id <= 0) {
      throw AppException(message);
    }
  }

  void _validateOptionalId(int? id, String message) {
    if (id != null && id <= 0) {
      throw AppException(message);
    }
  }

  String _emptyToDefault(String value, String defaultValue) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return defaultValue;
    }

    return trimmed;
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
