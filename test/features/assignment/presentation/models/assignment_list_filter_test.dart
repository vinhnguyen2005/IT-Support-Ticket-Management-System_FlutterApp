import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/features/assignment/domain/entities/assignment.dart';
import 'package:it_ticket_support_management/features/assignment/presentation/models/assignment_list_filter.dart';

void main() {
  final assignments = [
    _assignment(
      ticketId: 10,
      title: 'VPN issue',
      status: 'Processing',
      priority: 'High',
    ),
    _assignment(
      ticketId: 11,
      title: 'Printer issue',
      status: 'Assigned',
      priority: 'Medium',
    ),
  ];

  test('searches staff assignments by ticket data', () {
    final result = const AssignmentListFilter(query: 'vpn').apply(assignments);

    expect(result.map((assignment) => assignment.ticketId), [10]);
  });

  test('combines assignment status and priority filters', () {
    final result = const AssignmentListFilter(
      status: 'Assigned',
      priority: 'Medium',
    ).apply(assignments);

    expect(result.map((assignment) => assignment.ticketId), [11]);
  });
}

Assignment _assignment({
  required int ticketId,
  required String title,
  required String status,
  required String priority,
}) {
  return Assignment(
    id: ticketId,
    ticketId: ticketId,
    staffId: 7,
    assignedAt: DateTime(2026),
    isActive: true,
    ticketTitle: title,
    ticketDescription: '$title description',
    issueType: 'Network',
    priority: priority,
    status: status,
    ticketCreatedAt: DateTime(2026),
  );
}
