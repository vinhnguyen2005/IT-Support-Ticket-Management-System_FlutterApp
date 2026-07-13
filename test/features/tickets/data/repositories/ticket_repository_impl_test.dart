import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/features/tickets/data/datasources/i_ticket_local_data_source.dart';
import 'package:it_ticket_support_management/features/tickets/data/dtos/ticket_dto.dart';
import 'package:it_ticket_support_management/features/tickets/data/dtos/update_ticket_status_dto.dart';
import 'package:it_ticket_support_management/features/tickets/data/mappers/ticket_mapper.dart';
import 'package:it_ticket_support_management/features/tickets/data/repositories/ticket_repository_impl.dart';

void main() {
  group('TicketRepositoryImpl linear status workflow', () {
    final invalidJumps = <(String, String)>[
      ('Submitted', 'Processing'),
      ('Submitted', 'Resolved'),
      ('Submitted', 'Closed'),
      ('Assigned', 'Resolved'),
      ('Assigned', 'Closed'),
      ('Processing', 'Closed'),
    ];

    for (final jump in invalidJumps) {
      test('rejects ${jump.$1} -> ${jump.$2}', () async {
        final repository = _repository(_TicketSource(_ticket(status: jump.$1)));

        expect(
          () => repository.updateTicketStatus(
            ticketId: 10,
            status: jump.$2,
            changedByUserId: 2,
            changedByRole: 'user',
            solutionSummary: 'Should not skip a workflow step',
          ),
          throwsException,
        );
      });
    }

    test('allows Submitted -> Assigned', () async {
      final source = _TicketSource(_ticket(status: 'Submitted'));

      await _repository(
        source,
      ).updateTicketStatus(ticketId: 10, status: 'Assigned');

      expect(source.statusUpdate?.newStatus, 'Assigned');
    });

    test('allows Assigned -> Processing', () async {
      final source = _TicketSource(_ticket(status: 'Assigned'));

      await _repository(
        source,
      ).updateTicketStatus(ticketId: 10, status: 'Processing');

      expect(source.statusUpdate?.newStatus, 'Processing');
    });

    test('allows Processing -> Resolved with solution summary', () async {
      final source = _TicketSource(_ticket(status: 'Processing'));

      await _repository(source).updateTicketStatus(
        ticketId: 10,
        status: 'Resolved',
        solutionSummary: 'VPN connection verified',
      );

      expect(source.statusUpdate?.newStatus, 'Resolved');
    });
  });

  group('TicketRepositoryImpl status permissions', () {
    test('assigned ticket cannot skip processing', () async {
      final repository = _repository(
        _TicketSource(_ticket(status: 'Assigned')),
      );

      expect(
        () => repository.updateTicketStatus(
          ticketId: 10,
          status: 'Resolved',
          changedByUserId: 7,
          changedByRole: 'staff',
          solutionSummary: 'Attempted shortcut',
        ),
        throwsException,
      );
    });

    test('admin can cancel a processing ticket', () async {
      final source = _TicketSource(_ticket(status: 'Processing'));
      final repository = _repository(source);

      await repository.updateTicketStatus(
        ticketId: 10,
        status: 'Cancelled',
        changedByUserId: 1,
        changedByRole: 'admin',
        note: 'Duplicate request',
      );

      expect(source.statusUpdate?.newStatus, 'Cancelled');
    });

    test('admin must provide a cancellation reason', () async {
      final repository = _repository(
        _TicketSource(_ticket(status: 'Processing')),
      );

      expect(
        () => repository.updateTicketStatus(
          ticketId: 10,
          status: 'Cancelled',
          changedByUserId: 1,
          changedByRole: 'admin',
          note: '   ',
        ),
        throwsException,
      );
    });

    test('non-admin cannot cancel a ticket', () async {
      final repository = _repository(
        _TicketSource(_ticket(status: 'Assigned')),
      );

      expect(
        () => repository.updateTicketStatus(
          ticketId: 10,
          status: 'Cancelled',
          changedByUserId: 2,
          changedByRole: 'staff',
        ),
        throwsException,
      );
    });

    test('admin cannot cancel a resolved ticket', () async {
      final repository = _repository(
        _TicketSource(_ticket(status: 'Resolved')),
      );

      expect(
        () => repository.updateTicketStatus(
          ticketId: 10,
          status: 'Cancelled',
          changedByUserId: 1,
          changedByRole: 'admin',
        ),
        throwsException,
      );
    });

    test('requester can confirm a resolved ticket and close it', () async {
      final source = _TicketSource(_ticket(status: 'Resolved'));
      final repository = _repository(source);

      await repository.updateTicketStatus(
        ticketId: 10,
        status: 'Closed',
        changedByUserId: 2,
        changedByRole: 'user',
      );

      expect(source.statusUpdate?.newStatus, 'Closed');
    });

    test('another user cannot close the requester ticket', () async {
      final repository = _repository(
        _TicketSource(_ticket(status: 'Resolved')),
      );

      expect(
        () => repository.updateTicketStatus(
          ticketId: 10,
          status: 'Closed',
          changedByUserId: 3,
          changedByRole: 'user',
        ),
        throwsException,
      );
    });
  });
}

TicketRepositoryImpl _repository(_TicketSource source) =>
    TicketRepositoryImpl(localDataSource: source, mapper: const TicketMapper());

TicketDto _ticket({required String status}) => TicketDto(
  id: 10,
  title: 'VPN issue',
  description: 'Cannot connect',
  status: status,
  createdByUserId: 2,
  requestedId: 2,
  createdAt: DateTime(2026),
);

class _TicketSource implements ITicketLocalDataSource {
  _TicketSource(this.ticket);

  TicketDto ticket;
  UpdateTicketStatusDto? statusUpdate;

  @override
  Future<TicketDto?> getTicketById(int id) async => ticket;

  @override
  Future<void> updateTicketStatus(UpdateTicketStatusDto update) async {
    statusUpdate = update;
    ticket = TicketDto(
      id: ticket.id,
      title: ticket.title,
      description: ticket.description,
      status: update.newStatus,
      createdByUserId: ticket.createdByUserId,
      requestedId: ticket.requestedId,
      createdAt: ticket.createdAt,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
