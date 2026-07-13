import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/features/assignment/application/services/i_assignment_service.dart';
import 'package:it_ticket_support_management/features/assignment/presentation/viewmodels/ticket_assignment_view_model.dart';
import 'package:it_ticket_support_management/features/assignment/presentation/views/admin_ticket_assignment_page.dart';
import 'package:it_ticket_support_management/features/tickets/application/services/i_ticket_service.dart';
import 'package:it_ticket_support_management/features/tickets/domain/entities/ticket.dart';
import 'package:it_ticket_support_management/features/user_management/application/services/i_user_management_service.dart';
import 'package:it_ticket_support_management/features/user_management/domain/entities/managed_user.dart';

void main() {
  testWidgets('admin can search all tickets', (tester) async {
    final viewModel = TicketAssignmentViewModel(
      assignmentService: _AssignmentService(),
      ticketService: _TicketService([
        _ticket(id: 10, title: 'VPN issue'),
        _ticket(id: 11, title: 'Printer issue'),
      ]),
      userManagementService: _UserManagementService(),
      currentUserId: 1,
      currentUserRole: 'admin',
      mode: TicketAssignmentMode.adminAll,
    );

    await tester.pumpWidget(
      MaterialApp(home: AdminTicketAssignmentPage(viewModel: viewModel)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('queue-ticket-status-filter')), findsOneWidget);
    expect(
      find.byKey(const Key('queue-ticket-priority-filter')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('queue-ticket-search')),
      'printer',
    );
    await tester.pump();

    expect(find.text('Printer issue'), findsOneWidget);
    expect(find.text('VPN issue'), findsNothing);
    expect(find.text('1/2 tickets'), findsOneWidget);
  });
}

Ticket _ticket({required int id, required String title}) {
  return Ticket(
    id: id,
    title: title,
    description: '$title description',
    status: 'Submitted',
    priority: 'High',
    issueType: 'Network',
    createdAt: DateTime(2026),
  );
}

class _TicketService implements ITicketService {
  const _TicketService(this.tickets);

  final List<Ticket> tickets;

  @override
  Future<List<Ticket>> getTickets() async => tickets;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserManagementService implements IUserManagementService {
  @override
  Future<List<ManagedUser>> getUsers() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AssignmentService implements IAssignmentService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
