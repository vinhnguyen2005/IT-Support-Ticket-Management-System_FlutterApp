import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/features/assignment/application/services/i_assignment_service.dart';
import 'package:it_ticket_support_management/features/assignment/domain/entities/assignment.dart';
import 'package:it_ticket_support_management/features/assignment/domain/entities/progress_update.dart';
import 'package:it_ticket_support_management/features/assignment/presentation/viewmodels/technician_queue_view_model.dart';
import 'package:it_ticket_support_management/features/assignment/presentation/viewmodels/update_progress_view_model.dart';
import 'package:it_ticket_support_management/features/assignment/presentation/views/technician_queue_page.dart';
import 'package:it_ticket_support_management/features/assignment/presentation/views/update_progress_page.dart';

void main() {
  group('TechnicianQueuePage', () {
    testWidgets('shows a loader while assigned tickets are loading', (
      tester,
    ) async {
      final pending = Completer<List<Assignment>>();
      final service = _StaffService(assignmentsFuture: pending.future);

      await tester.pumpWidget(_queueApp(service));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(const []);
      await tester.pumpAndSettle();
    });

    testWidgets('shows an empty message when staff has no assigned tickets', (
      tester,
    ) async {
      final service = _StaffService(assignments: const []);

      await tester.pumpWidget(_queueApp(service));
      await tester.pumpAndSettle();

      expect(find.text('No tickets are assigned to you.'), findsOneWidget);
    });

    testWidgets('renders assignment details and the latest progress note', (
      tester,
    ) async {
      final service = _StaffService(
        assignments: [_assignment(lastProgressMessage: 'Checking router')],
      );

      await tester.pumpWidget(_queueApp(service));
      await tester.pumpAndSettle();

      expect(find.text('VPN issue'), findsOneWidget);
      expect(find.text('VPN disconnects repeatedly.'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Assigned'), findsOneWidget);
      expect(find.text('Network'), findsOneWidget);
      expect(find.text('Latest: Checking router'), findsOneWidget);
    });
  });

  group('UpdateProgressPage', () {
    testWidgets('renders ticket details, next statuses, and note history', (
      tester,
    ) async {
      final service = _StaffService(
        assignment: _assignment(),
        updates: [_update('Initial diagnosis')],
      );

      await tester.pumpWidget(_progressApp(service));
      await tester.pumpAndSettle();

      expect(find.text('VPN issue'), findsOneWidget);
      expect(find.text('Current: Assigned'), findsOneWidget);
      expect(find.text('Processing'), findsOneWidget);
      expect(find.text('Resolved'), findsNothing);
      expect(find.text('Closed'), findsNothing);
      expect(find.text('Initial diagnosis'), findsOneWidget);
      expect(find.text('Status note'), findsOneWidget);
    });

    testWidgets('shows no available change for a closed ticket', (
      tester,
    ) async {
      final service = _StaffService(assignment: _assignment(status: 'Closed'));

      await tester.pumpWidget(_progressApp(service));
      await tester.pumpAndSettle();

      expect(
        find.text('No status changes are available for this ticket.'),
        findsOneWidget,
      );
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save update'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('processing can only move to resolved', (tester) async {
      final service = _StaffService(
        assignment: _assignment(status: 'Processing'),
      );

      await tester.pumpWidget(_progressApp(service));
      await tester.pumpAndSettle();

      expect(find.text('Resolved'), findsOneWidget);
      expect(find.text('Pending'), findsNothing);
      expect(find.text('Closed'), findsNothing);
    });

    testWidgets('submits the selected status and trimmed progress note', (
      tester,
    ) async {
      final service = _StaffService(assignment: _assignment());

      await tester.pumpWidget(_progressApp(service));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '  Started work  ');
      await tester.tap(find.widgetWithText(FilledButton, 'Save update'));
      await tester.pumpAndSettle();

      expect(service.updatedStatus, 'Processing');
      expect(service.updatedNote, 'Started work');
      expect(service.addedMessage, 'Started work');
      expect(find.text('Ticket status updated.'), findsOneWidget);
    });
  });
}

Widget _queueApp(_StaffService service) => MaterialApp(
  home: TechnicianQueuePage(
    viewModel: TechnicianQueueViewModel(
      assignmentService: service,
      staffId: 7,
      userRole: 'staff',
    ),
  ),
);

Widget _progressApp(_StaffService service) => MaterialApp(
  home: UpdateProgressPage(
    viewModel: UpdateProgressViewModel(
      assignmentService: service,
      staffId: 7,
      ticketId: 10,
    ),
  ),
);

Assignment _assignment({
  String status = 'Assigned',
  String? lastProgressMessage,
}) => Assignment(
  id: 1,
  ticketId: 10,
  staffId: 7,
  assignedAt: DateTime(2026),
  isActive: true,
  ticketTitle: 'VPN issue',
  ticketDescription: 'VPN disconnects repeatedly.',
  issueType: 'Network',
  priority: 'High',
  status: status,
  ticketCreatedAt: DateTime(2026),
  lastProgressMessage: lastProgressMessage,
);

ProgressUpdate _update(String message) => ProgressUpdate(
  id: 1,
  ticketId: 10,
  staffId: 7,
  message: message,
  createdAt: DateTime(2026),
);

class _StaffService implements IAssignmentService {
  _StaffService({
    this.assignments = const [],
    this.assignmentsFuture,
    this.assignment,
    this.updates = const [],
  });

  final List<Assignment> assignments;
  final Future<List<Assignment>>? assignmentsFuture;
  final Assignment? assignment;
  List<ProgressUpdate> updates;
  String? updatedStatus;
  String? updatedNote;
  String? addedMessage;

  @override
  Future<List<Assignment>> getAssignmentsForStaff(int staffId) =>
      assignmentsFuture ?? Future.value(assignments);

  @override
  Future<Assignment?> getAssignmentByTicket({
    required int ticketId,
    required int staffId,
  }) async => assignment;

  @override
  Future<List<ProgressUpdate>> getProgressUpdates(int ticketId) async =>
      updates;

  @override
  Future<void> updateTicketStatus({
    required int ticketId,
    required int staffId,
    required String status,
    String? note,
    String? solutionSummary,
  }) async {
    updatedStatus = status;
    updatedNote = note;
  }

  @override
  Future<ProgressUpdate> addProgressUpdate({
    required int ticketId,
    required int staffId,
    required String message,
  }) async {
    addedMessage = message;
    final update = _update(message);
    updates = [...updates, update];
    return update;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
