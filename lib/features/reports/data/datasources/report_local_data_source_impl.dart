import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/sla_persistence.dart';
import '../../../../core/enums/sla_status.dart';
import '../../domain/entities/report_filter.dart';
import '../dtos/feedback_summary_report_dto.dart';
import '../dtos/low_rating_feedback_report_dto.dart';
import '../dtos/processing_time_report_dto.dart';
import '../dtos/sla_attention_report_dto.dart';
import '../dtos/sla_summary_report_dto.dart';
import '../dtos/staff_performance_report_dto.dart';
import '../dtos/ticket_volume_report_dto.dart';
import '../dtos/user_report_dto.dart';
import 'i_report_local_data_source.dart';

class ReportLocalDataSourceImpl implements IReportLocalDataSource {
  const ReportLocalDataSourceImpl({required this.database});

  final Database database;

  @override
  Future<SlaSummaryReportDto> getSlaSummaryReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async {
    await SlaPersistence.refreshBreaches(database);
    final ticketFilter = _ticketFilter(filter);
    final now = DateTime.now().toIso8601String();
    final rows = await database.rawQuery(
      '''
      WITH clock(nowValue) AS (SELECT julianday(?))
      SELECT
        SUM(CASE WHEN LOWER(t.status) <> 'cancelled'
          AND t.slaExceptionReason IS NULL THEN 1 ELSE 0 END)
          AS total_actionable,
        SUM(CASE WHEN t.slaExceptionReason IS NULL
          AND LOWER(t.status) <> 'cancelled'
          AND t.responseDueAt IS NOT NULL
          AND t.firstRespondedAt IS NOT NULL
          AND julianday(t.firstRespondedAt) <= julianday(t.responseDueAt)
          THEN 1 ELSE 0 END) AS response_met,
        SUM(CASE WHEN t.slaExceptionReason IS NULL
          AND LOWER(t.status) <> 'cancelled'
          AND t.responseDueAt IS NOT NULL
          AND (
            (t.firstRespondedAt IS NOT NULL
              AND julianday(t.firstRespondedAt) > julianday(t.responseDueAt))
            OR (t.firstRespondedAt IS NULL
              AND clock.nowValue >= julianday(t.responseDueAt))
          )
          THEN 1 ELSE 0 END) AS response_breached,
        SUM(CASE WHEN t.slaExceptionReason IS NULL
          AND LOWER(t.status) <> 'cancelled'
          AND t.resolutionDueAt IS NOT NULL
          AND t.slaCompletedAt IS NOT NULL
          AND julianday(t.slaCompletedAt) <= julianday(t.resolutionDueAt)
          THEN 1 ELSE 0 END) AS resolution_met,
        SUM(CASE WHEN t.slaExceptionReason IS NULL
          AND LOWER(t.status) <> 'cancelled'
          AND t.resolutionDueAt IS NOT NULL
          AND (
            (t.slaCompletedAt IS NOT NULL
              AND julianday(t.slaCompletedAt) > julianday(t.resolutionDueAt))
            OR (t.slaCompletedAt IS NULL
              AND clock.nowValue >= julianday(t.resolutionDueAt))
          )
          THEN 1 ELSE 0 END) AS resolution_breached,
        SUM(CASE WHEN t.slaCompletedAt IS NULL
          AND t.slaExceptionReason IS NULL
          AND LOWER(t.status) <> 'cancelled'
          AND t.resolutionDueAt IS NOT NULL
          AND clock.nowValue < julianday(t.resolutionDueAt)
          AND clock.nowValue >= julianday(t.createdAt) +
            ((julianday(t.resolutionDueAt) - julianday(t.createdAt)) * 0.75)
          THEN 1 ELSE 0 END) AS currently_at_risk,
        SUM(CASE WHEN t.slaCompletedAt IS NULL
          AND t.slaExceptionReason IS NULL
          AND LOWER(t.status) <> 'cancelled'
          AND t.resolutionDueAt IS NOT NULL
          AND clock.nowValue >= julianday(t.resolutionDueAt)
          THEN 1 ELSE 0 END) AS currently_breached,
        SUM(CASE WHEN t.slaExceptionReason IS NOT NULL
          OR LOWER(t.status) = 'cancelled' THEN 1 ELSE 0 END) AS exempt
      FROM ${AppDatabase.ticketsTable} t
      CROSS JOIN clock
      WHERE DATE(t.createdAt) BETWEEN ? AND ?
      ${ticketFilter.sql}
      ''',
      [now, startDate, endDate, ...ticketFilter.args],
    );
    return SlaSummaryReportDto.fromMap(rows.first);
  }

  @override
  Future<List<TicketVolumeReportDto>> getTicketVolumeReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async {
    final ticketFilter = _ticketFilter(filter);
    final rows = await database.rawQuery(
      '''
      SELECT
        DATE(t.createdAt) AS date,
        COUNT(t.id) AS total_tickets,
        SUM(CASE WHEN LOWER(t.status) = 'submitted' THEN 1 ELSE 0 END)
          AS submitted_tickets,
        SUM(CASE WHEN LOWER(t.status) = 'assigned' THEN 1 ELSE 0 END)
          AS assigned_tickets,
        SUM(CASE WHEN LOWER(t.status) = 'processing' THEN 1 ELSE 0 END)
          AS processing_tickets,
        SUM(CASE WHEN LOWER(t.status) = 'resolved' THEN 1 ELSE 0 END)
          AS resolved_tickets,
        SUM(CASE WHEN LOWER(t.status) = 'closed' THEN 1 ELSE 0 END)
          AS closed_tickets,
        SUM(CASE WHEN LOWER(t.status) = 'cancelled' THEN 1 ELSE 0 END)
          AS cancelled_tickets
      FROM ${AppDatabase.ticketsTable} t
      WHERE DATE(t.createdAt) BETWEEN ? AND ?
      ${ticketFilter.sql}
      GROUP BY DATE(t.createdAt)
      ORDER BY DATE(t.createdAt) DESC
      ''',
      [startDate, endDate, ...ticketFilter.args],
    );
    return rows.map(TicketVolumeReportDto.fromMap).toList(growable: false);
  }

  @override
  Future<List<StaffPerformanceReportDto>> getStaffPerformanceReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async {
    final ticketFilter = _ticketFilter(filter);
    final rows = await database.rawQuery(
      '''
      SELECT
        u.id AS staff_id,
        u.fullName AS staff_name,
        COUNT(DISTINCT CASE
          WHEN DATE(a.assignedAt) BETWEEN ? AND ? THEN a.ticketId END)
          AS assigned_tickets,
        COUNT(DISTINCT CASE
          WHEN DATE(t.resolvedAt) BETWEEN ? AND ? THEN t.id END)
          AS resolved_tickets
      FROM ${AppDatabase.usersTable} u
      LEFT JOIN ${AppDatabase.ticketAssignmentsTable} a ON u.id = a.staffId
      LEFT JOIN ${AppDatabase.ticketsTable} t ON t.id = a.ticketId
      WHERE LOWER(u.role) = 'staff'
        AND (
          DATE(a.assignedAt) BETWEEN ? AND ?
          OR DATE(t.resolvedAt) BETWEEN ? AND ?
        )
      ${ticketFilter.sql}
      GROUP BY u.id, u.fullName
      ORDER BY resolved_tickets DESC, assigned_tickets DESC, u.fullName ASC
      ''',
      [
        startDate,
        endDate,
        startDate,
        endDate,
        startDate,
        endDate,
        startDate,
        endDate,
        ...ticketFilter.args,
      ],
    );
    return rows.map(StaffPerformanceReportDto.fromMap).toList(growable: false);
  }

  @override
  Future<List<ProcessingTimeReportDto>> getProcessingTimeReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async {
    final ticketFilter = _ticketFilter(filter);
    final rows = await database.rawQuery(
      '''
      SELECT
        c.name AS category_name,
        COUNT(t.id) AS completed_tickets,
        AVG((julianday(t.resolvedAt) - julianday(t.createdAt)) * 24)
          AS average_hours
      FROM ${AppDatabase.ticketsTable} t
      JOIN ${AppDatabase.categoriesTable} c ON t.categoryId = c.id
      WHERE t.resolvedAt IS NOT NULL
        AND LOWER(t.status) IN ('resolved', 'closed')
        AND DATE(t.resolvedAt) BETWEEN ? AND ?
      ${ticketFilter.sql}
      GROUP BY c.id, c.name
      ORDER BY average_hours DESC, c.name ASC
      ''',
      [startDate, endDate, ...ticketFilter.args],
    );
    return rows.map(ProcessingTimeReportDto.fromMap).toList(growable: false);
  }

  @override
  Future<List<UserReportDto>> getUserReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async {
    final ticketFilter = _ticketFilter(filter);
    final rows = await database.rawQuery(
      '''
      SELECT
        u.id AS user_id,
        u.fullName AS full_name,
        u.username AS username,
        u.role AS role,
        d.name AS department_name,
        u.isActive AS is_active,
        u.lastLoginAt AS last_login_at,
        COUNT(DISTINCT CASE
          WHEN DATE(t.createdAt) BETWEEN ? AND ? THEN t.id END)
          AS created_tickets,
        COUNT(DISTINCT CASE
          WHEN DATE(t.resolvedAt) BETWEEN ? AND ? THEN t.id END)
          AS completed_tickets
      FROM ${AppDatabase.usersTable} u
      LEFT JOIN ${AppDatabase.departmentsTable} d ON u.departmentId = d.id
      LEFT JOIN ${AppDatabase.ticketsTable} t ON u.id = t.createdByUserId
      WHERE 1 = 1
      ${ticketFilter.sql}
      GROUP BY
        u.id, u.fullName, u.username, u.role, d.name, u.isActive, u.lastLoginAt
      ORDER BY u.role ASC, u.fullName ASC
      ''',
      [startDate, endDate, startDate, endDate, ...ticketFilter.args],
    );
    return rows.map(UserReportDto.fromMap).toList(growable: false);
  }

  @override
  Future<List<SlaAttentionReportDto>> getSlaAttentionReport({
    ReportFilter filter = const ReportFilter(),
  }) async {
    await SlaPersistence.refreshBreaches(database);
    final ticketFilter = _ticketFilter(filter);
    final now = DateTime.now().toIso8601String();
    final rows = await database.rawQuery(
      '''
      WITH clock(nowValue) AS (SELECT julianday(?))
      SELECT
        t.id AS ticket_id,
        t.title,
        t.priority,
        t.status AS ticket_status,
        t.createdAt AS created_at,
        t.resolutionDueAt AS resolution_due_at,
        u.fullName AS staff_name,
        c.name AS category_name,
        CASE
          WHEN clock.nowValue >= julianday(t.resolutionDueAt)
            THEN '${SlaStatus.breached.name}'
          ELSE '${SlaStatus.atRisk.name}'
        END AS sla_status
      FROM ${AppDatabase.ticketsTable} t
      CROSS JOIN clock
      LEFT JOIN ${AppDatabase.usersTable} u ON u.id = t.assignedStaffId
      LEFT JOIN ${AppDatabase.categoriesTable} c ON c.id = t.categoryId
      WHERE t.slaCompletedAt IS NULL
        AND t.slaExceptionReason IS NULL
        AND LOWER(t.status) NOT IN ('cancelled', 'resolved', 'closed')
        AND t.resolutionDueAt IS NOT NULL
        AND clock.nowValue >= julianday(t.createdAt) +
          ((julianday(t.resolutionDueAt) - julianday(t.createdAt)) * 0.75)
      ${ticketFilter.sql}
      ORDER BY
        CASE WHEN clock.nowValue >= julianday(t.resolutionDueAt)
          THEN 0 ELSE 1 END,
        julianday(t.resolutionDueAt) ASC
      ''',
      [now, ...ticketFilter.args],
    );
    return rows.map(SlaAttentionReportDto.fromMap).toList(growable: false);
  }

  @override
  Future<FeedbackSummaryReportDto> getFeedbackSummaryReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async {
    final closedFilter = _ticketFilter(filter);
    final closedRows = await database.rawQuery(
      '''
      SELECT COUNT(t.id) AS closed_tickets
      FROM ${AppDatabase.ticketsTable} t
      WHERE t.closedAt IS NOT NULL
        AND DATE(t.closedAt) BETWEEN ? AND ?
      ${closedFilter.sql}
      ''',
      [startDate, endDate, ...closedFilter.args],
    );

    final feedbackFilter = _ticketFilter(filter);
    final feedbackRows = await database.rawQuery(
      '''
      SELECT
        COUNT(f.id) AS total_feedback,
        AVG(f.supportRating) AS average_rating,
        SUM(CASE WHEN f.supportRating <= 2 THEN 1 ELSE 0 END) AS low_rating_count,
        SUM(CASE WHEN f.supportRating = 1 THEN 1 ELSE 0 END) AS rating_1_count,
        SUM(CASE WHEN f.supportRating = 2 THEN 1 ELSE 0 END) AS rating_2_count,
        SUM(CASE WHEN f.supportRating = 3 THEN 1 ELSE 0 END) AS rating_3_count,
        SUM(CASE WHEN f.supportRating = 4 THEN 1 ELSE 0 END) AS rating_4_count,
        SUM(CASE WHEN f.supportRating = 5 THEN 1 ELSE 0 END) AS rating_5_count
      FROM ${AppDatabase.feedbackTable} f
      JOIN ${AppDatabase.ticketsTable} t ON t.id = f.ticketId
      WHERE t.closedAt IS NOT NULL
        AND DATE(t.closedAt) BETWEEN ? AND ?
      ${feedbackFilter.sql}
      ''',
      [startDate, endDate, ...feedbackFilter.args],
    );
    return FeedbackSummaryReportDto.fromMap({
      ...feedbackRows.first,
      'closed_tickets': closedRows.first['closed_tickets'],
    });
  }

  @override
  Future<List<LowRatingFeedbackReportDto>> getLowRatingFeedbackReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async {
    final ticketFilter = _ticketFilter(filter);
    final rows = await database.rawQuery(
      '''
      SELECT
        f.id AS feedback_id,
        f.ticketId AS ticket_id,
        t.title AS ticket_title,
        u.fullName AS user_name,
        f.supportRating AS rating,
        f.comment,
        f.createdAt AS created_at
      FROM ${AppDatabase.feedbackTable} f
      JOIN ${AppDatabase.ticketsTable} t ON t.id = f.ticketId
      JOIN ${AppDatabase.usersTable} u ON u.id = f.reviewerUserId
      WHERE f.supportRating <= 2
        AND t.closedAt IS NOT NULL
        AND DATE(t.closedAt) BETWEEN ? AND ?
      ${ticketFilter.sql}
      ORDER BY f.supportRating ASC, datetime(f.createdAt) DESC
      ''',
      [startDate, endDate, ...ticketFilter.args],
    );
    return rows.map(LowRatingFeedbackReportDto.fromMap).toList(growable: false);
  }

  _SqlFilter _ticketFilter(ReportFilter filter) {
    final conditions = <String>[];
    final args = <Object?>[];
    if (filter.priority != null) {
      conditions.add('LOWER(t.priority) = LOWER(?)');
      args.add(filter.priority);
    }
    if (filter.categoryId != null) {
      conditions.add('t.categoryId = ?');
      args.add(filter.categoryId);
    }
    if (filter.staffId != null) {
      conditions.add('t.assignedStaffId = ?');
      args.add(filter.staffId);
    }
    final status = filter.slaStatus;
    if (status != null) {
      final now = DateTime.now().toIso8601String();
      switch (status) {
        case SlaStatus.onTrack:
          conditions.add('''
            t.slaCompletedAt IS NULL
            AND t.slaExceptionReason IS NULL
            AND LOWER(t.status) NOT IN ('cancelled', 'resolved', 'closed')
            AND t.resolutionDueAt IS NOT NULL
            AND julianday(?) < julianday(t.createdAt) +
              ((julianday(t.resolutionDueAt) - julianday(t.createdAt)) * 0.75)
          ''');
          args.add(now);
        case SlaStatus.atRisk:
          conditions.add('''
            t.slaCompletedAt IS NULL
            AND t.slaExceptionReason IS NULL
            AND LOWER(t.status) NOT IN ('cancelled', 'resolved', 'closed')
            AND t.resolutionDueAt IS NOT NULL
            AND julianday(?) < julianday(t.resolutionDueAt)
            AND julianday(?) >= julianday(t.createdAt) +
              ((julianday(t.resolutionDueAt) - julianday(t.createdAt)) * 0.75)
          ''');
          args.addAll([now, now]);
        case SlaStatus.breached:
          conditions.add('''
            t.slaCompletedAt IS NULL
            AND t.slaExceptionReason IS NULL
            AND LOWER(t.status) NOT IN ('cancelled', 'resolved', 'closed')
            AND t.resolutionDueAt IS NOT NULL
            AND julianday(?) >= julianday(t.resolutionDueAt)
          ''');
          args.add(now);
        case SlaStatus.met:
          conditions.add('''
            t.slaCompletedAt IS NOT NULL
            AND t.resolutionDueAt IS NOT NULL
            AND julianday(t.slaCompletedAt) <= julianday(t.resolutionDueAt)
          ''');
        case SlaStatus.breachedResolved:
          conditions.add('''
            t.slaCompletedAt IS NOT NULL
            AND t.resolutionDueAt IS NOT NULL
            AND julianday(t.slaCompletedAt) > julianday(t.resolutionDueAt)
          ''');
        case SlaStatus.exempt:
          conditions.add(
            "(t.slaExceptionReason IS NOT NULL OR LOWER(t.status) = 'cancelled')",
          );
      }
    }
    if (conditions.isEmpty) return const _SqlFilter('', []);
    return _SqlFilter(
      conditions.map((condition) => 'AND ($condition)').join('\n'),
      args,
    );
  }
}

class _SqlFilter {
  const _SqlFilter(this.sql, this.args);

  final String sql;
  final List<Object?> args;
}
