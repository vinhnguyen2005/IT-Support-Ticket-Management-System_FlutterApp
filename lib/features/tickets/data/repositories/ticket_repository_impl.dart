import '../../../../core/enums/issue_type.dart';
import '../../../../core/enums/priority_level.dart';
import '../../../../core/enums/ticket_status.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_status_note.dart';
import '../../domain/repositories/i_ticket_repository.dart';
import '../datasources/i_ticket_local_data_source.dart';
import '../dtos/ticket_dto.dart';
import '../dtos/update_ticket_status_dto.dart';
import '../mappers/ticket_mapper.dart';

class TicketRepositoryImpl implements ITicketRepository {
  const TicketRepositoryImpl({
    required ITicketLocalDataSource localDataSource,
    required TicketMapper mapper,
  }) : _localDataSource = localDataSource,
       _mapper = mapper;

  final ITicketLocalDataSource _localDataSource;
  final TicketMapper _mapper;

  static const Map<TicketStatus, Set<TicketStatus>> _allowedStatusTransitions =
      {
        TicketStatus.submitted: {TicketStatus.assigned, TicketStatus.cancelled},
        TicketStatus.assigned: {TicketStatus.processing, TicketStatus.resolved},
        TicketStatus.processing: {TicketStatus.resolved},
        TicketStatus.resolved: {TicketStatus.closed},
      };

  @override
  Future<List<Ticket>> getTickets() async {
    final tickets = await _localDataSource.getTickets();
    return tickets.map(_mapper.mapToEntity).toList();
  }

  @override
  Future<List<Ticket>> getTicketsByRequester(int requesterId) async {
    final tickets = await _localDataSource.getTicketsByRequester(requesterId);
    return tickets.map(_mapper.mapToEntity).toList();
  }

  @override
  Future<List<Ticket>> getTicketsByAssignee(int assigneeId) async {
    final tickets = await _localDataSource.getTicketsByAssignee(assigneeId);
    return tickets.map(_mapper.mapToEntity).toList();
  }

  @override
  Future<Ticket?> getTicketById(int id) async {
    final ticket = await _localDataSource.getTicketById(id);
    if (ticket == null) {
      return null;
    }

    return _mapper.mapToEntity(ticket);
  }

  @override
  Future<List<TicketStatusNote>> getStatusNotesByTicketId(int ticketId) async {
    final notes = await _localDataSource.getStatusNotesByTicketId(ticketId);
    return notes.map(_mapper.mapStatusNoteToEntity).toList();
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
  }) async {
    final now = DateTime.now();
    final ticket = TicketDto(
      title: title.trim(),
      description: description.trim(),
      issueType: issueType.trim().isEmpty
          ? IssueType.defaultValue
          : IssueType.fromValue(issueType).value,
      priority: priority.trim().isEmpty
          ? PriorityLevel.defaultValue
          : PriorityLevel.fromValue(priority).value,
      status: TicketStatus.submitted.value,
      attachmentUrl: attachmentUrl,
      requestedId: requesterId,
      createdByUserId: requesterId,
      categoryId: categoryId,
      createdAt: now,
      updatedAt: now,
    );

    _validateTicketContent(ticket);

    final id = await _localDataSource.insertTicket(ticket);
    final createdTicket = await _localDataSource.getTicketById(id);
    return _mapper.mapToEntity(
      createdTicket ??
          TicketDto(
            id: id,
            title: ticket.title,
            description: ticket.description,
            issueType: ticket.issueType,
            priority: ticket.priority,
            status: ticket.status,
            attachmentUrl: ticket.attachmentUrl,
            requestedId: ticket.requestedId,
            createdByUserId: ticket.createdByUserId,
            categoryId: ticket.categoryId,
            createdAt: ticket.createdAt,
            updatedAt: ticket.updatedAt,
          ),
    );
  }

  @override
  Future<Ticket> updateTicket(Ticket ticket) async {
    final ticketId = ticket.id;
    if (ticketId == null) {
      throw const AppException('Ticket id is required for update.');
    }

    final existingTicket = await _localDataSource.getTicketById(ticketId);
    if (existingTicket == null) {
      throw const AppException('Ticket was not found.');
    }

    final dto = _mapper.mapToDto(ticket);
    _validateTicketContent(dto);

    if (_parseStatus(dto.status) != _parseStatus(existingTicket.status)) {
      throw const AppException(
        'Use updateTicketStatus to change ticket status.',
      );
    }

    await _localDataSource.updateTicket(
      TicketDto(
        id: dto.id,
        title: dto.title.trim(),
        description: dto.description.trim(),
        issueType: dto.issueType.trim().isEmpty
            ? IssueType.defaultValue
            : IssueType.fromValue(dto.issueType).value,
        priority: dto.priority.trim().isEmpty
            ? PriorityLevel.defaultValue
            : PriorityLevel.fromValue(dto.priority).value,
        status: _normalizeStatus(existingTicket.status),
        attachmentUrl: dto.attachmentUrl,
        requestedId: dto.requestedId,
        assignedId: dto.assignedId,
        categoryId: dto.categoryId,
        solutionSummary: dto.solutionSummary,
        resolvedAt: dto.resolvedAt,
        createdAt: existingTicket.createdAt,
        updatedAt: DateTime.now(),
        createdByUserId: dto.createdByUserId,
        updatedByUserId: dto.updatedByUserId,
        isDeleted: dto.isDeleted,
      ),
    );

    final updatedTicket = await _localDataSource.getTicketById(ticketId);
    if (updatedTicket == null) {
      throw const AppException('Ticket was not found after update.');
    }

    return _mapper.mapToEntity(updatedTicket);
  }

  @override
  Future<Ticket> updateTicketStatus({
    required int ticketId,
    required String status,
    int? changedByUserId,
    String? changedByRole,
    String? note,
    String? solutionSummary,
  }) async {
    final ticket = await _localDataSource.getTicketById(ticketId);
    if (ticket == null) {
      throw const AppException('Ticket was not found.');
    }

    final normalizedStatus = _normalizeStatus(status);
    _validateStatusTransition(
      ticket: ticket,
      currentStatus: ticket.status,
      nextStatus: normalizedStatus,
      changedByUserId: changedByUserId,
      changedByRole: changedByRole,
      note: note,
    );

    if (TicketStatus.fromValue(normalizedStatus) == TicketStatus.resolved &&
        (solutionSummary == null || solutionSummary.trim().isEmpty)) {
      throw const AppException(
        'Solution summary is required when resolving a ticket.',
      );
    }

    await _localDataSource.updateTicketStatus(
      UpdateTicketStatusDto(
        ticketId: ticketId,
        oldStatus: ticket.status,
        newStatus: normalizedStatus,
        changedByUserId: changedByUserId,
        note: note ?? solutionSummary,
        solutionSummary: solutionSummary,
      ),
    );

    final updatedTicket = await _localDataSource.getTicketById(ticketId);
    if (updatedTicket == null) {
      throw const AppException('Ticket was not found after status update.');
    }

    return _mapper.mapToEntity(updatedTicket);
  }

  @override
  Future<void> deleteTicket(int id) async {
    final deletedRows = await _localDataSource.deleteTicket(id);
    if (deletedRows == 0) {
      throw const AppException('Ticket was not found.');
    }
  }

  void _validateTicketContent(TicketDto ticket) {
    if (ticket.title.trim().isEmpty) {
      throw const AppException('Ticket title is required.');
    }

    if (ticket.description.trim().isEmpty) {
      throw const AppException('Ticket description is required.');
    }
  }

  void _validateStatusTransition({
    required TicketDto ticket,
    required String currentStatus,
    required String nextStatus,
    int? changedByUserId,
    String? changedByRole,
    String? note,
  }) {
    final current = _parseStatus(currentStatus);
    final next = _parseStatus(nextStatus);

    if (current == next) {
      return;
    }

    final role = UserRole.fromValue(changedByRole ?? '');
    if (next == TicketStatus.cancelled) {
      if (role != UserRole.admin) {
        throw const AppException('Only admins can cancel a ticket.');
      }
      if (current == TicketStatus.resolved || current == TicketStatus.closed) {
        throw const AppException(
          'Resolved or closed tickets cannot be cancelled.',
        );
      }
      if (note == null || note.trim().isEmpty) {
        throw const AppException('Cancellation reason is required.');
      }
      return;
    }

    if (current == TicketStatus.resolved && next == TicketStatus.closed) {
      final requesterId = ticket.createdByUserId ?? ticket.requestedId;
      if (role != UserRole.user ||
          changedByUserId == null ||
          changedByUserId != requesterId) {
        throw const AppException(
          'Only the ticket requester can confirm and close a resolved ticket.',
        );
      }
    }

    final allowedNextStatuses = _allowedStatusTransitions[current];
    if (allowedNextStatuses == null || !allowedNextStatuses.contains(next)) {
      throw AppException(
        'Ticket status cannot change from $currentStatus to $nextStatus.',
      );
    }
  }

  String _normalizeStatus(String status) {
    final parsedStatus = TicketStatus.tryParse(status);
    if (parsedStatus == null) {
      throw const AppException('Ticket status is required.');
    }

    return parsedStatus.value;
  }

  TicketStatus _parseStatus(String status) {
    final parsedStatus = TicketStatus.tryParse(status);
    if (parsedStatus == null) {
      throw AppException('Unsupported ticket status: $status.');
    }

    return parsedStatus;
  }
}
