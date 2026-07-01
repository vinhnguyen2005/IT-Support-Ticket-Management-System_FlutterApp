import '../../domain/entities/ticket.dart';
import '../dtos/create_ticket_request_dto.dart';
import '../dtos/ticket_dto.dart';
import '../dtos/update_ticket_status_dto.dart';

class TicketMapper {
  const TicketMapper();

  Ticket mapToEntity(TicketDto dto) {
    return Ticket(
      id: dto.id,
      title: dto.title,
      description: dto.description,
      status: _normalizeStatus(dto.status),
      priority: dto.priority,
      issueType: dto.issueType,
      attachmentUrl: dto.attachmentUrl,
      requestedId: dto.requestedId ?? dto.createdByUserId,
      assignedId: dto.assignedId,
      categoryId: dto.categoryId,
      solutionSummary: dto.solutionSummary,
      resolvedAt: dto.resolvedAt,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      createdByUserId: dto.createdByUserId ?? dto.requestedId,
      updatedByUserId: dto.updatedByUserId,
      isDeleted: dto.isDeleted,
    );
  }

  TicketDto mapToDto(Ticket entity) {
    return TicketDto(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      issueType: entity.issueType,
      priority: entity.priority,
      status: _normalizeStatus(entity.status),
      attachmentUrl: entity.attachmentUrl,
      requestedId: entity.requestedId ?? entity.createdByUserId,
      assignedId: entity.assignedId,
      categoryId: entity.categoryId,
      solutionSummary: entity.solutionSummary,
      resolvedAt: entity.resolvedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      createdByUserId: entity.createdByUserId ?? entity.requestedId,
      updatedByUserId: entity.updatedByUserId,
      isDeleted: entity.isDeleted,
    );
  }

  CreateTicketRequestDto mapToCreateRequest(Ticket entity) {
    return CreateTicketRequestDto(
      title: entity.title,
      description: entity.description,
      issueType: entity.issueType,
      priority: entity.priority,
      status: _normalizeStatus(entity.status),
      attachmentUrl: entity.attachmentUrl,
      categoryId: entity.categoryId,
      requestedId: entity.requestedId ?? entity.createdByUserId,
    );
  }

  UpdateTicketStatusDto mapToStatusUpdate({
    required Ticket ticket,
    required String newStatus,
    int? changedByUserId,
    String? note,
  }) {
    final ticketId = ticket.id;
    if (ticketId == null) {
      throw ArgumentError('Ticket id is required for status update.');
    }

    return UpdateTicketStatusDto(
      ticketId: ticketId,
      oldStatus: _normalizeStatus(ticket.status),
      newStatus: _normalizeStatus(newStatus),
      changedByUserId: changedByUserId,
      note: note,
    );
  }

  String _normalizeStatus(String status) {
    final key = status.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
    switch (key) {
      case 'open':
      case 'submitted':
        return 'Open';
      case 'assigned':
        return 'Assigned';
      case 'inprogress':
      case 'processing':
      case 'pending':
        return 'InProgress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      case 'reopened':
        return 'Reopened';
    }

    return status;
  }
}
