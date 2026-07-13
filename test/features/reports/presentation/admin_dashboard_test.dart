import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/features/reports/application/services/i_report_service.dart';
import 'package:it_ticket_support_management/features/reports/domain/entities/processing_time_report.dart';
import 'package:it_ticket_support_management/features/reports/domain/entities/staff_performance_report.dart';
import 'package:it_ticket_support_management/features/reports/domain/entities/ticket_volume_report.dart';
import 'package:it_ticket_support_management/features/reports/domain/entities/user_report.dart';
import 'package:it_ticket_support_management/features/reports/presentation/viewmodels/admin_dashboard_view_model.dart';
import 'package:it_ticket_support_management/features/reports/presentation/views/admin_dashboard_page.dart';
import 'package:provider/provider.dart';

void main() {
  test('loads all report sections and calculates accurate totals', () async {
    final service = _ReportServiceFake();
    final viewModel = AdminDashboardViewModel(reportService: service);

    await viewModel.loadDashboardData('2026-07-01', '2026-07-31');

    expect(service.lastStartDate, '2026-07-01');
    expect(service.lastEndDate, '2026-07-31');
    expect(viewModel.totalTicketsOverall, 8);
    expect(viewModel.totalOpenOverall, 4);
    expect(viewModel.totalResolvedOverall, 2);
    expect(viewModel.totalClosedOverall, 1);
    expect(viewModel.totalCancelledOverall, 1);
    expect(viewModel.completionRate, closeTo(3 / 7, 0.0001));
    expect(viewModel.activeUsers, 1);
    expect(viewModel.inactiveUsers, 1);
    expect(viewModel.userReports, hasLength(2));
    expect(viewModel.errorMessage, isNull);
  });

  testWidgets('renders detailed tables including the user report', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final viewModel = AdminDashboardViewModel(
      reportService: _ReportServiceFake(),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const MaterialApp(home: AdminDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Admin reports'), findsOneWidget);
    expect(find.text('Ticket activity by day'), findsOneWidget);
    expect(find.text('Staff performance'), findsOneWidget);
    expect(find.text('Processing time by category'), findsOneWidget);
    expect(find.text('User report'), findsOneWidget);
    expect(find.text('Alice User'), findsOneWidget);
    expect(find.text('Chart'), findsNothing);
  });

  testWidgets('renders the report header and metrics on a phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) =>
            AdminDashboardViewModel(reportService: _ReportServiceFake()),
        child: const MaterialApp(home: AdminDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Operations intelligence'), findsOneWidget);
    expect(find.text('30 days'), findsOneWidget);
    expect(find.text('Ticket overview'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ReportServiceFake implements IReportService {
  String? lastStartDate;
  String? lastEndDate;

  void _recordRange(String startDate, String endDate) {
    lastStartDate = startDate;
    lastEndDate = endDate;
  }

  @override
  Future<List<TicketVolumeReport>> getTicketVolumeReport(
    String startDate,
    String endDate,
  ) async {
    _recordRange(startDate, endDate);
    return const [
      TicketVolumeReport(
        date: '2026-07-14',
        totalTickets: 8,
        submittedTickets: 1,
        assignedTickets: 1,
        processingTickets: 2,
        resolvedTickets: 2,
        closedTickets: 1,
        cancelledTickets: 1,
      ),
    ];
  }

  @override
  Future<List<StaffPerformanceReport>> getStaffPerformanceReport(
    String startDate,
    String endDate,
  ) async {
    _recordRange(startDate, endDate);
    return [
      StaffPerformanceReport(
        staffId: 2,
        staffName: 'Support Staff',
        assignedTickets: 4,
        resolvedTickets: 3,
      ),
    ];
  }

  @override
  Future<List<ProcessingTimeReport>> getProcessingTimeReport(
    String startDate,
    String endDate,
  ) async {
    _recordRange(startDate, endDate);
    return const [
      ProcessingTimeReport(
        categoryName: 'Network Issue',
        completedTickets: 3,
        averageHours: 5.5,
      ),
    ];
  }

  @override
  Future<List<UserReport>> getUserReport(
    String startDate,
    String endDate,
  ) async {
    _recordRange(startDate, endDate);
    return [
      UserReport(
        userId: 1,
        fullName: 'Alice User',
        username: 'alice',
        role: 'user',
        departmentName: 'IT Support',
        isActive: true,
        lastLoginAt: DateTime(2026, 7, 14),
        createdTickets: 5,
        completedTickets: 3,
      ),
      const UserReport(
        userId: 2,
        fullName: 'Inactive User',
        username: 'inactive',
        role: 'user',
        isActive: false,
        createdTickets: 0,
        completedTickets: 0,
      ),
    ];
  }
}
