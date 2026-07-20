import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/core/enums/sla_status.dart';
import 'package:it_ticket_support_management/features/assignment/data/dtos/assignment_dto.dart';
import 'package:it_ticket_support_management/features/assignment/data/mappers/assignment_mapper.dart';
import 'package:it_ticket_support_management/features/reports/data/dtos/sla_summary_report_dto.dart';
import 'package:it_ticket_support_management/features/reports/domain/entities/sla_summary_report.dart';
import 'package:it_ticket_support_management/features/tickets/data/dtos/ticket_dto.dart';
import 'package:it_ticket_support_management/features/tickets/data/mappers/ticket_mapper.dart';

void main() {
  group('SLA status metadata', () {
    test('flags warning and breach states only', () {
      expect(SlaStatus.atRisk.isWarning, isTrue);
      expect(SlaStatus.onTrack.isWarning, isFalse);
      expect(SlaStatus.breached.isBreach, isTrue);
      expect(SlaStatus.breachedResolved.isBreach, isTrue);
      expect(SlaStatus.met.isBreach, isFalse);
      expect(SlaStatus.exempt.isBreach, isFalse);
    });
  });

  group('SLA report calculations', () {
    test('calculates response and resolution compliance', () {
      const report = SlaSummaryReport(
        totalActionable: 10,
        responseMet: 8,
        responseBreached: 2,
        resolutionMet: 6,
        resolutionBreached: 4,
        currentlyAtRisk: 1,
        currentlyBreached: 2,
        exempt: 3,
      );

      expect(report.responseComplianceRate, 0.8);
      expect(report.resolutionComplianceRate, 0.6);
    });

    test('returns zero rates when no SLA has completed or breached', () {
      const report = SlaSummaryReport(
        totalActionable: 0,
        responseMet: 0,
        responseBreached: 0,
        resolutionMet: 0,
        resolutionBreached: 0,
        currentlyAtRisk: 0,
        currentlyBreached: 0,
        exempt: 0,
      );

      expect(report.responseComplianceRate, 0);
      expect(report.resolutionComplianceRate, 0);
    });

    test('DTO tolerates null aggregate values from an empty SQL result', () {
      final dto = SlaSummaryReportDto.fromMap(const {});

      expect(dto.totalActionable, 0);
      expect(dto.toEntity().responseComplianceRate, 0);
    });
  });

  group('SLA mapping', () {
    test('ticket DTO and mapper preserve every SLA field', () {
      final responseDueAt = DateTime(2026, 7, 20, 9);
      final resolutionDueAt = DateTime(2026, 7, 20, 12);
      final respondedAt = DateTime(2026, 7, 20, 8, 30);
      final completedAt = DateTime(2026, 7, 20, 11);
      final dto = TicketDto.fromMap({
        'id': 10,
        'title': 'VPN issue',
        'description': 'Cannot connect',
        'createdAt': DateTime(2026, 7, 20, 8).toIso8601String(),
        'firstRespondedAt': respondedAt.toIso8601String(),
        'responseDueAt': responseDueAt.toIso8601String(),
        'resolutionDueAt': resolutionDueAt.toIso8601String(),
        'slaCompletedAt': completedAt.toIso8601String(),
        'slaBreachedAt': null,
        'slaExceptionReason': 'Approved maintenance',
        'slaExceptionApprovedBy': 1,
      });

      final entity = const TicketMapper().mapToEntity(dto);
      final mappedBack = const TicketMapper().mapToDto(entity).toMap();

      expect(entity.firstRespondedAt, respondedAt);
      expect(entity.responseDueAt, responseDueAt);
      expect(entity.resolutionDueAt, resolutionDueAt);
      expect(entity.slaCompletedAt, completedAt);
      expect(entity.slaExceptionReason, 'Approved maintenance');
      expect(entity.slaExceptionApprovedBy, 1);
      expect(mappedBack['responseDueAt'], responseDueAt.toIso8601String());
      expect(mappedBack['resolutionDueAt'], resolutionDueAt.toIso8601String());
    });

    test('assignment DTO and mapper preserve SLA queue fields', () {
      final responseDueAt = DateTime(2026, 7, 20, 9);
      final resolutionDueAt = DateTime(2026, 7, 20, 12);
      final dto = AssignmentDto.fromMap({
        'id': 1,
        'ticketId': 10,
        'staffId': 2,
        'assignedAt': DateTime(2026, 7, 20, 8, 30).toIso8601String(),
        'isActive': 1,
        'createdAt': DateTime(2026, 7, 20, 8, 30).toIso8601String(),
        'ticketCreatedAt': DateTime(2026, 7, 20, 8).toIso8601String(),
        'firstRespondedAt': DateTime(2026, 7, 20, 8, 30).toIso8601String(),
        'responseDueAt': responseDueAt.toIso8601String(),
        'resolutionDueAt': resolutionDueAt.toIso8601String(),
        'slaCompletedAt': null,
        'slaExceptionReason': null,
      });

      final assignment = const AssignmentMapper().mapToEntity(dto);

      expect(assignment.responseDueAt, responseDueAt);
      expect(assignment.resolutionDueAt, resolutionDueAt);
      expect(
        assignment.resolutionSlaStatusAt(DateTime(2026, 7, 20, 11)),
        SlaStatus.atRisk,
      );
    });
  });
}
