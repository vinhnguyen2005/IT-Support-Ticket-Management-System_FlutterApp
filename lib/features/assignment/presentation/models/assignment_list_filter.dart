import '../../../../core/enums/priority_level.dart';
import '../../../../core/enums/ticket_status.dart';
import '../../domain/entities/assignment.dart';

class AssignmentListFilter {
  const AssignmentListFilter({
    this.query = '',
    this.status = '',
    this.priority = '',
  });

  final String query;
  final String status;
  final String priority;

  List<Assignment> apply(List<Assignment> assignments) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedStatus = status.trim();
    final normalizedPriority = priority.trim();

    return assignments
        .where((assignment) {
          final matchesStatus =
              normalizedStatus.isEmpty ||
              TicketStatus.fromValue(assignment.status).value ==
                  normalizedStatus;
          final matchesPriority =
              normalizedPriority.isEmpty ||
              PriorityLevel.fromValue(assignment.priority).value ==
                  normalizedPriority;

          if (!matchesStatus || !matchesPriority) {
            return false;
          }

          if (normalizedQuery.isEmpty) {
            return true;
          }

          return assignment.ticketId.toString().contains(normalizedQuery) ||
              assignment.ticketTitle.toLowerCase().contains(normalizedQuery) ||
              assignment.ticketDescription.toLowerCase().contains(
                normalizedQuery,
              ) ||
              assignment.status.toLowerCase().contains(normalizedQuery) ||
              assignment.priority.toLowerCase().contains(normalizedQuery) ||
              assignment.issueType.toLowerCase().contains(normalizedQuery) ||
              (assignment.lastProgressMessage?.toLowerCase().contains(
                    normalizedQuery,
                  ) ??
                  false);
        })
        .toList(growable: false);
  }
}
