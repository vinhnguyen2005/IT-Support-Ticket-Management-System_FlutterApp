import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/core/enums/sla_status.dart';
import 'package:it_ticket_support_management/features/tickets/domain/entities/ticket.dart';

void main() {
  group('Ticket resolution SLA', () {
    final createdAt = DateTime(2026, 7, 17, 8);
    final dueAt = DateTime(2026, 7, 18, 8);

    test('is on track before 75 percent of the deadline', () {
      final ticket = _ticket(createdAt: createdAt, resolutionDueAt: dueAt);

      expect(
        ticket.resolutionSlaStatusAt(DateTime(2026, 7, 18, 1, 59)),
        SlaStatus.onTrack,
      );
    });

    test('is at risk after 75 percent of the deadline', () {
      final ticket = _ticket(createdAt: createdAt, resolutionDueAt: dueAt);

      expect(
        ticket.resolutionSlaStatusAt(DateTime(2026, 7, 18, 2)),
        SlaStatus.atRisk,
      );
    });

    test('is breached at the deadline', () {
      final ticket = _ticket(createdAt: createdAt, resolutionDueAt: dueAt);

      expect(ticket.resolutionSlaStatusAt(dueAt), SlaStatus.breached);
    });

    test('has a safe on-track fallback when no deadline is configured', () {
      final ticket = _ticket(createdAt: createdAt);

      expect(
        ticket.resolutionSlaStatusAt(DateTime(2026, 7, 30)),
        SlaStatus.onTrack,
      );
    });

    test('keeps met result after on-time resolution', () {
      final ticket = _ticket(
        createdAt: createdAt,
        resolutionDueAt: dueAt,
        status: 'Resolved',
        slaCompletedAt: DateTime(2026, 7, 18, 7, 30),
      );

      expect(
        ticket.resolutionSlaStatusAt(DateTime(2026, 7, 19)),
        SlaStatus.met,
      );
    });

    test('completion exactly at the deadline is met', () {
      final ticket = _ticket(
        createdAt: createdAt,
        resolutionDueAt: dueAt,
        status: 'Resolved',
        slaCompletedAt: dueAt,
      );

      expect(
        ticket.resolutionSlaStatusAt(DateTime(2026, 7, 19)),
        SlaStatus.met,
      );
    });

    test('falls back to resolvedAt for migrated completed tickets', () {
      final ticket = _ticket(
        createdAt: createdAt,
        resolutionDueAt: dueAt,
        status: 'Resolved',
        resolvedAt: DateTime(2026, 7, 18, 7),
      );

      expect(
        ticket.resolutionSlaStatusAt(DateTime(2026, 7, 19)),
        SlaStatus.met,
      );
    });

    test('keeps breached result after late resolution', () {
      final ticket = _ticket(
        createdAt: createdAt,
        resolutionDueAt: dueAt,
        status: 'Resolved',
        slaCompletedAt: DateTime(2026, 7, 18, 9),
      );

      expect(
        ticket.resolutionSlaStatusAt(DateTime(2026, 7, 19)),
        SlaStatus.breachedResolved,
      );
    });

    test('cancelled ticket is exempt', () {
      final ticket = _ticket(
        createdAt: createdAt,
        resolutionDueAt: dueAt,
        status: 'Cancelled',
      );

      expect(
        ticket.resolutionSlaStatusAt(DateTime(2026, 7, 19)),
        SlaStatus.exempt,
      );
    });

    test('approved SLA exception is exempt even when still open', () {
      final ticket = _ticket(
        createdAt: createdAt,
        resolutionDueAt: dueAt,
        slaExceptionReason: 'Vendor outage',
      );

      expect(
        ticket.resolutionSlaStatusAt(DateTime(2026, 7, 19)),
        SlaStatus.exempt,
      );
    });
  });

  group('Ticket response SLA', () {
    test('uses the first assignment as the response milestone', () {
      final ticket = _ticket(
        createdAt: DateTime(2026, 7, 17, 8),
        responseDueAt: DateTime(2026, 7, 17, 12),
        firstRespondedAt: DateTime(2026, 7, 17, 10),
      );

      expect(ticket.responseSlaStatusAt(DateTime(2026, 7, 18)), SlaStatus.met);
    });

    test('reports a late first response', () {
      final ticket = _ticket(
        createdAt: DateTime(2026, 7, 17, 8),
        responseDueAt: DateTime(2026, 7, 17, 12),
        firstRespondedAt: DateTime(2026, 7, 17, 13),
      );

      expect(
        ticket.responseSlaStatusAt(DateTime(2026, 7, 18)),
        SlaStatus.breachedResolved,
      );
    });

    test('is on track before 75 percent without a response', () {
      final ticket = _ticket(
        createdAt: DateTime(2026, 7, 17, 8),
        responseDueAt: DateTime(2026, 7, 17, 12),
      );

      expect(
        ticket.responseSlaStatusAt(DateTime(2026, 7, 17, 10, 59)),
        SlaStatus.onTrack,
      );
    });

    test('is at risk at 75 percent without a response', () {
      final ticket = _ticket(
        createdAt: DateTime(2026, 7, 17, 8),
        responseDueAt: DateTime(2026, 7, 17, 12),
      );

      expect(
        ticket.responseSlaStatusAt(DateTime(2026, 7, 17, 11)),
        SlaStatus.atRisk,
      );
    });

    test('is breached at the response deadline', () {
      final dueAt = DateTime(2026, 7, 17, 12);
      final ticket = _ticket(
        createdAt: DateTime(2026, 7, 17, 8),
        responseDueAt: dueAt,
      );

      expect(ticket.responseSlaStatusAt(dueAt), SlaStatus.breached);
    });

    test('response exactly at the deadline is met', () {
      final dueAt = DateTime(2026, 7, 17, 12);
      final ticket = _ticket(
        createdAt: DateTime(2026, 7, 17, 8),
        responseDueAt: dueAt,
        firstRespondedAt: dueAt,
      );

      expect(ticket.responseSlaStatusAt(DateTime(2026, 7, 18)), SlaStatus.met);
    });

    test('cancelled response SLA is exempt', () {
      final ticket = _ticket(
        createdAt: DateTime(2026, 7, 17, 8),
        responseDueAt: DateTime(2026, 7, 17, 12),
        status: 'Cancelled',
      );

      expect(
        ticket.responseSlaStatusAt(DateTime(2026, 7, 18)),
        SlaStatus.exempt,
      );
    });

    test('has a safe on-track fallback when no response deadline exists', () {
      final ticket = _ticket(createdAt: DateTime(2026, 7, 17, 8));

      expect(
        ticket.responseSlaStatusAt(DateTime(2026, 7, 30)),
        SlaStatus.onTrack,
      );
    });
  });
}

Ticket _ticket({
  required DateTime createdAt,
  DateTime? responseDueAt,
  DateTime? resolutionDueAt,
  DateTime? firstRespondedAt,
  DateTime? resolvedAt,
  DateTime? slaCompletedAt,
  String? slaExceptionReason,
  String status = 'Submitted',
}) {
  return Ticket(
    title: 'VPN issue',
    description: 'Cannot connect to the company VPN.',
    status: status,
    createdAt: createdAt,
    responseDueAt: responseDueAt,
    resolutionDueAt: resolutionDueAt,
    firstRespondedAt: firstRespondedAt,
    resolvedAt: resolvedAt,
    slaCompletedAt: slaCompletedAt,
    slaExceptionReason: slaExceptionReason,
  );
}
