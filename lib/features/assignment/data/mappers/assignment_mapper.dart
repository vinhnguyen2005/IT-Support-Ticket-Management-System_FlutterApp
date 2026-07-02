import '../../../../core/enums/issue_type.dart';
import '../../../../core/enums/priority_level.dart';
import '../../../../core/enums/ticket_status.dart';
import '../../domain/entities/assignment.dart';
import '../dtos/assignment_dto.dart';

class AssignmentMapper {
  const AssignmentMapper();

  Assignment mapToEntity(AssignmentDto dto) {
    return Assignment(
      id: dto.id ?? 0,
      ticketId: dto.ticketId,
      staffId: dto.staffId,
      assignedByUserId: dto.assignedByUserId,
      assignedAt: dto.assignedAt,
      note: dto.note,
      isActive: dto.isActive,
      ticketTitle: dto.ticketTitle ?? 'Untitled ticket',
      ticketDescription: dto.ticketDescription ?? '',
      issueType: dto.issueType ?? IssueType.defaultValue,
      priority: dto.priority ?? PriorityLevel.defaultValue,
      status: dto.status ?? TicketStatus.defaultValue,
      ticketCreatedAt: dto.ticketCreatedAt ?? dto.createdAt,
      ticketUpdatedAt: dto.ticketUpdatedAt,
      lastProgressMessage: dto.lastProgressMessage,
    );
  }
}
