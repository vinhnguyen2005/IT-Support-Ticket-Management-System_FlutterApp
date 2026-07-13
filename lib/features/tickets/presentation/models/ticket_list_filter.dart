import '../../../../core/enums/priority_level.dart';
import '../../../../core/enums/ticket_status.dart';
import '../../domain/entities/ticket.dart';

class TicketListFilter {
  const TicketListFilter({
    this.query = '',
    this.status = '',
    this.priority = '',
  });

  final String query;
  final String status;
  final String priority;

  List<Ticket> apply(List<Ticket> tickets) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedStatus = status.trim();
    final normalizedPriority = priority.trim();

    return tickets
        .where((ticket) {
          final matchesStatus =
              normalizedStatus.isEmpty ||
              TicketStatus.fromValue(ticket.status).value == normalizedStatus;
          final matchesPriority =
              normalizedPriority.isEmpty ||
              PriorityLevel.fromValue(ticket.priority).value ==
                  normalizedPriority;

          if (!matchesStatus || !matchesPriority) {
            return false;
          }

          if (normalizedQuery.isEmpty) {
            return true;
          }

          final id = ticket.id?.toString() ?? '';
          return id.contains(normalizedQuery) ||
              ticket.title.toLowerCase().contains(normalizedQuery) ||
              ticket.description.toLowerCase().contains(normalizedQuery) ||
              ticket.status.toLowerCase().contains(normalizedQuery) ||
              ticket.priority.toLowerCase().contains(normalizedQuery) ||
              ticket.issueType.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }
}
