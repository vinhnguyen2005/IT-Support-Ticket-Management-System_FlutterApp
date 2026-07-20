import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/core/enums/sla_status.dart';
import 'package:it_ticket_support_management/features/tickets/presentation/widgets/sla_status_badge.dart';

void main() {
  testWidgets('shows remaining time for on-track and at-risk SLA', (
    tester,
  ) async {
    final now = DateTime(2026, 7, 20, 8);

    await _pumpBadge(
      tester,
      status: SlaStatus.onTrack,
      now: now,
      dueAt: now.add(const Duration(hours: 2, minutes: 15)),
    );
    expect(find.text('SLA: 2h 15m left'), findsOneWidget);

    await _pumpBadge(
      tester,
      status: SlaStatus.atRisk,
      now: now,
      dueAt: now.add(const Duration(minutes: 30)),
      prefix: 'Response SLA',
    );
    expect(find.text('Response SLA: 30m left'), findsOneWidget);
  });

  testWidgets('shows overdue duration for active breach', (tester) async {
    final now = DateTime(2026, 7, 20, 10);

    await _pumpBadge(
      tester,
      status: SlaStatus.breached,
      now: now,
      dueAt: now.subtract(const Duration(hours: 1, minutes: 5)),
    );

    expect(find.text('SLA: Overdue 1h 5m'), findsOneWidget);
  });

  for (final status in const [
    SlaStatus.met,
    SlaStatus.breachedResolved,
    SlaStatus.exempt,
  ]) {
    testWidgets('shows terminal label for ${status.name}', (tester) async {
      await _pumpBadge(tester, status: status);

      expect(find.text('SLA: ${status.label}'), findsOneWidget);
      expect(find.byKey(Key('sla-${status.name}')), findsOneWidget);
    });
  }

  testWidgets('uses status label safely when deadline is absent', (
    tester,
  ) async {
    await _pumpBadge(tester, status: SlaStatus.onTrack);

    expect(find.text('SLA: On track'), findsOneWidget);
  });
}

Future<void> _pumpBadge(
  WidgetTester tester, {
  required SlaStatus status,
  DateTime? dueAt,
  DateTime? now,
  String prefix = 'SLA',
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SlaStatusBadge(
          status: status,
          dueAt: dueAt,
          now: now,
          prefix: prefix,
        ),
      ),
    ),
  );
}
