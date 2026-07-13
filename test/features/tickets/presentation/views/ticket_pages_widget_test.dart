import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/features/tickets/application/services/i_ticket_service.dart';
import 'package:it_ticket_support_management/features/tickets/domain/entities/ticket.dart';
import 'package:it_ticket_support_management/features/tickets/presentation/viewmodels/create_ticket_view_model.dart';
import 'package:it_ticket_support_management/features/tickets/presentation/viewmodels/ticket_list_view_model.dart';
import 'package:it_ticket_support_management/features/tickets/presentation/views/create_ticket_page.dart';
import 'package:it_ticket_support_management/features/tickets/presentation/views/ticket_list_page.dart';

void main() {
  group('CreateTicketPage', () {
    testWidgets('renders the ticket form', (tester) async {
      final service = _TicketService();

      await tester.pumpWidget(
        MaterialApp(
          home: CreateTicketPage(
            requesterId: 7,
            viewModel: CreateTicketViewModel(service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create ticket'), findsWidgets);
      expect(find.widgetWithText(TextField, 'Title'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Description'), findsOneWidget);
      expect(find.text('Issue type'), findsOneWidget);
      expect(find.text('Priority'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Browse'), findsOneWidget);
    });

    testWidgets('submits the form and returns success to the caller', (
      tester,
    ) async {
      final service = _TicketService();
      bool? result;
      await _largeViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateTicketPage(
                        requesterId: 7,
                        viewModel: CreateTicketViewModel(service),
                      ),
                    ),
                  );
                },
                child: const Text('Open form'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Title'),
        'Printer offline',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'The finance printer cannot be reached.',
      );
      final submit = find.widgetWithText(FilledButton, 'Create ticket');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(service.createdTitle, 'Printer offline');
      expect(
        service.createdDescription,
        'The finance printer cannot be reached.',
      );
      expect(service.createdRequesterId, 7);
      expect(service.createdCategoryId, 4);
    });
  });

  group('TicketListPage', () {
    testWidgets('shows an empty state', (tester) async {
      final service = _TicketService();

      await tester.pumpWidget(_listApp(service));
      await tester.pumpAndSettle();

      expect(find.text('No tickets found.'), findsOneWidget);
      expect(service.requesterLoads, 1);
    });

    testWidgets('renders requester tickets and filters by search text', (
      tester,
    ) async {
      final service = _TicketService(
        tickets: [_ticket(1, 'VPN unavailable'), _ticket(2, 'Printer offline')],
      );

      await tester.pumpWidget(_listApp(service));
      await tester.pumpAndSettle();

      expect(find.text('VPN unavailable'), findsOneWidget);
      expect(find.text('Printer offline'), findsOneWidget);
      expect(find.text('2/2 tickets'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Search tickets'),
        'printer',
      );
      await tester.pump();

      expect(find.text('VPN unavailable'), findsNothing);
      expect(find.text('Printer offline'), findsOneWidget);
      expect(find.text('1/2 tickets'), findsOneWidget);
    });

    testWidgets('paginates requester tickets five at a time', (tester) async {
      final service = _TicketService(
        tickets: List.generate(
          6,
          (index) => _ticket(index + 1, 'Ticket ${index + 1}'),
        ),
      );
      await _largeViewport(tester);

      await tester.pumpWidget(_listApp(service));
      await tester.pumpAndSettle();

      expect(find.text('Page 1 of 2'), findsOneWidget);
      expect(find.text('Showing 1-5 of 6 tickets'), findsOneWidget);
      await tester.tap(find.byTooltip('Next page'));
      await tester.pump();
      expect(find.text('Page 2 of 2'), findsOneWidget);
      expect(find.text('Ticket 1'), findsOneWidget);
      expect(find.text('Ticket 6'), findsNothing);
    });
  });
}

Widget _listApp(_TicketService service) => MaterialApp(
  home: TicketListPage(requesterId: 7, viewModel: TicketListViewModel(service)),
);

Future<void> _largeViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Ticket _ticket(int id, String title) => Ticket(
  id: id,
  title: title,
  description: 'Description for $title',
  createdAt: DateTime(2026, 1, id),
);

class _TicketService implements ITicketService {
  _TicketService({this.tickets = const []});

  List<Ticket> tickets;
  int requesterLoads = 0;
  String? createdTitle;
  String? createdDescription;
  int? createdRequesterId;
  int? createdCategoryId;

  @override
  Future<List<Ticket>> getTicketsByRequester(int requesterId) async {
    requesterLoads++;
    return tickets;
  }

  @override
  Future<Ticket> createTicket({
    required String title,
    required String description,
    String issueType = 'Other',
    String priority = 'Medium',
    int? requesterId,
    int? categoryId,
    String? attachmentUrl,
  }) async {
    createdTitle = title;
    createdDescription = description;
    createdRequesterId = requesterId;
    createdCategoryId = categoryId;
    final ticket = _ticket(tickets.length + 1, title);
    tickets = [...tickets, ticket];
    return ticket;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
