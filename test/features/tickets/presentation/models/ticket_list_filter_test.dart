import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/features/tickets/domain/entities/ticket.dart';
import 'package:it_ticket_support_management/features/tickets/presentation/models/ticket_list_filter.dart';

void main() {
  final tickets = [
    _ticket(
      id: 10,
      title: 'VPN connection issue',
      status: 'Processing',
      priority: 'High',
      issueType: 'Network',
    ),
    _ticket(
      id: 11,
      title: 'Printer paper jam',
      status: 'Assigned',
      priority: 'Medium',
      issueType: 'Hardware',
    ),
    _ticket(
      id: 12,
      title: 'VPN account request',
      status: 'Resolved',
      priority: 'Low',
      issueType: 'Access',
    ),
  ];

  test('searches across id and ticket text fields', () {
    expect(
      const TicketListFilter(
        query: 'vpn',
      ).apply(tickets).map((ticket) => ticket.id),
      [10, 12],
    );
    expect(
      const TicketListFilter(
        query: '11',
      ).apply(tickets).map((ticket) => ticket.id),
      [11],
    );
  });

  test('combines search, status, and priority filters', () {
    final result = const TicketListFilter(
      query: 'network',
      status: 'Processing',
      priority: 'High',
    ).apply(tickets);

    expect(result.map((ticket) => ticket.id), [10]);
  });

  test('returns no ticket when one filter does not match', () {
    final result = const TicketListFilter(
      status: 'Resolved',
      priority: 'High',
    ).apply(tickets);

    expect(result, isEmpty);
  });
}

Ticket _ticket({
  required int id,
  required String title,
  required String status,
  required String priority,
  required String issueType,
}) {
  return Ticket(
    id: id,
    title: title,
    description: '$title description',
    status: status,
    priority: priority,
    issueType: issueType,
    createdAt: DateTime(2026),
  );
}
