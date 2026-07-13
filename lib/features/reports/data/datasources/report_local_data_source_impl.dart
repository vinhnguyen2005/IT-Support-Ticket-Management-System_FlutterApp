import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../dtos/processing_time_report_dto.dart';
import '../dtos/staff_performance_report_dto.dart';
import '../dtos/ticket_volume_report_dto.dart';
import '../dtos/user_report_dto.dart';
import 'i_report_local_data_source.dart';

class ReportLocalDataSourceImpl implements IReportLocalDataSource {
  const ReportLocalDataSourceImpl({required this.database});

  final Database database;

  @override
  Future<List<TicketVolumeReportDto>> getTicketVolumeReport(
    String startDate,
    String endDate,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT
        DATE(createdAt) AS date,
        COUNT(id) AS total_tickets,
        SUM(CASE WHEN LOWER(status) = 'submitted' THEN 1 ELSE 0 END)
          AS submitted_tickets,
        SUM(CASE WHEN LOWER(status) = 'assigned' THEN 1 ELSE 0 END)
          AS assigned_tickets,
        SUM(CASE WHEN LOWER(status) = 'processing' THEN 1 ELSE 0 END)
          AS processing_tickets,
        SUM(CASE WHEN LOWER(status) = 'resolved' THEN 1 ELSE 0 END)
          AS resolved_tickets,
        SUM(CASE WHEN LOWER(status) = 'closed' THEN 1 ELSE 0 END)
          AS closed_tickets,
        SUM(CASE WHEN LOWER(status) = 'cancelled' THEN 1 ELSE 0 END)
          AS cancelled_tickets
      FROM ${AppDatabase.ticketsTable}
      WHERE DATE(createdAt) BETWEEN ? AND ?
      GROUP BY DATE(createdAt)
      ORDER BY DATE(createdAt) DESC
      ''',
      [startDate, endDate],
    );
    return rows.map(TicketVolumeReportDto.fromMap).toList(growable: false);
  }

  @override
  Future<List<StaffPerformanceReportDto>> getStaffPerformanceReport(
    String startDate,
    String endDate,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT
        u.id AS staff_id,
        u.fullName AS staff_name,
        COUNT(t.id) AS assigned_tickets,
        SUM(
          CASE WHEN LOWER(t.status) IN ('resolved', 'closed')
          THEN 1 ELSE 0 END
        ) AS resolved_tickets
      FROM ${AppDatabase.usersTable} u
      LEFT JOIN ${AppDatabase.ticketsTable} t
        ON u.id = t.assignedStaffId
        AND DATE(t.createdAt) BETWEEN ? AND ?
      WHERE LOWER(u.role) = 'staff'
      GROUP BY u.id, u.fullName
      ORDER BY resolved_tickets DESC, assigned_tickets DESC, u.fullName ASC
      ''',
      [startDate, endDate],
    );
    return rows.map(StaffPerformanceReportDto.fromMap).toList(growable: false);
  }

  @override
  Future<List<ProcessingTimeReportDto>> getProcessingTimeReport(
    String startDate,
    String endDate,
  ) async {
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
        AND DATE(t.createdAt) BETWEEN ? AND ?
      GROUP BY c.id, c.name
      ORDER BY average_hours DESC, c.name ASC
      ''',
      [startDate, endDate],
    );
    return rows.map(ProcessingTimeReportDto.fromMap).toList(growable: false);
  }

  @override
  Future<List<UserReportDto>> getUserReport(
    String startDate,
    String endDate,
  ) async {
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
        COUNT(t.id) AS created_tickets,
        SUM(
          CASE WHEN LOWER(t.status) IN ('resolved', 'closed')
          THEN 1 ELSE 0 END
        ) AS completed_tickets
      FROM ${AppDatabase.usersTable} u
      LEFT JOIN ${AppDatabase.departmentsTable} d ON u.departmentId = d.id
      LEFT JOIN ${AppDatabase.ticketsTable} t
        ON u.id = t.createdByUserId
        AND DATE(t.createdAt) BETWEEN ? AND ?
      GROUP BY
        u.id,
        u.fullName,
        u.username,
        u.role,
        d.name,
        u.isActive,
        u.lastLoginAt
      ORDER BY u.role ASC, u.fullName ASC
      ''',
      [startDate, endDate],
    );
    return rows.map(UserReportDto.fromMap).toList(growable: false);
  }
}
