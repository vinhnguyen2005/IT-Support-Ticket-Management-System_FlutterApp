import '../../../../core/enums/ticket_status.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_status_note.dart';
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

  TicketStatusNote mapStatusNoteToEntity(UpdateTicketStatusDto dto) {
    return TicketStatusNote(
      fromStatus: dto.oldStatus,
      toStatus: _normalizeStatus(dto.newStatus),
      changedByUserId: dto.changedByUserId,
      note: dto.note,
      changedAt: dto.changedAt,
    );
  }

  String _normalizeStatus(String status) {
    return TicketStatus.tryParse(status)?.value ?? status;
  }
}
