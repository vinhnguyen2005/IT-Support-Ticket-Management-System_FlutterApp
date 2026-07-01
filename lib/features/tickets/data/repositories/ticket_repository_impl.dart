import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/ticket.dart';
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

  static const Map<String, Set<String>> _allowedStatusTransitions = {
    'open': {'assigned', 'inprogress', 'resolved', 'closed'},
    'assigned': {'inprogress', 'resolved', 'closed'},
    'inprogress': {'assigned', 'resolved', 'closed'},
    'resolved': {'closed'},
    'closed': {'reopened'},
    'reopened': {'assigned', 'inprogress', 'resolved', 'closed'},
  };

  static const Map<String, String> _statusDisplayNames = {
    'open': 'Open',
    'assigned': 'Assigned',
    'inprogress': 'InProgress',
    'resolved': 'Resolved',
    'closed': 'Closed',
    'reopened': 'Reopened',
  };

  static const Map<String, String> _legacyStatusAliases = {
    'submitted': 'open',
    'processing': 'inprogress',
    'pending': 'inprogress',
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
  Future<Ticket> createTicket({
    required String title,
    required String description,
    String issueType = 'General',
    String priority = 'Medium',
    int? requesterId,
    int? categoryId,
    String? attachmentUrl,
  }) async {
    final now = DateTime.now();
    final ticket = TicketDto(
      title: title.trim(),
      description: description.trim(),
      issueType: issueType.trim().isEmpty ? 'General' : issueType.trim(),
      priority: priority.trim().isEmpty ? 'Medium' : priority.trim(),
      status: 'Open',
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

    if (_statusKey(dto.status) != _statusKey(existingTicket.status)) {
      throw const AppException(
        'Use updateTicketStatus to change ticket status.',
      );
    }

    await _localDataSource.updateTicket(
      TicketDto(
        id: dto.id,
        title: dto.title.trim(),
        description: dto.description.trim(),
        issueType: dto.issueType.trim().isEmpty ? 'General' : dto.issueType,
        priority: dto.priority.trim().isEmpty ? 'Medium' : dto.priority,
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
    String? note,
    String? solutionSummary,
  }) async {
    final ticket = await _localDataSource.getTicketById(ticketId);
    if (ticket == null) {
      throw const AppException('Ticket was not found.');
    }

    final normalizedStatus = _normalizeStatus(status);
    _validateStatusTransition(
      currentStatus: ticket.status,
      nextStatus: normalizedStatus,
    );

    if (normalizedStatus.toLowerCase() == 'resolved' &&
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
    required String currentStatus,
    required String nextStatus,
  }) {
    final current = _statusKey(currentStatus);
    final next = _statusKey(nextStatus);

    if (current == next) {
      return;
    }

    final allowedNextStatuses = _allowedStatusTransitions[current];
    if (allowedNextStatuses == null || !allowedNextStatuses.contains(next)) {
      throw AppException(
        'Ticket status cannot change from $currentStatus to $nextStatus.',
      );
    }
  }

  String _normalizeStatus(String status) {
    final statusKey = _statusKey(status);
    if (statusKey.isEmpty) {
      throw const AppException('Ticket status is required.');
    }

    final displayName = _statusDisplayNames[statusKey];
    if (displayName == null) {
      throw AppException('Unsupported ticket status: $status.');
    }

    return displayName;
  }

  String _statusKey(String status) {
    final key = status.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
    return _legacyStatusAliases[key] ?? key;
  }
}
