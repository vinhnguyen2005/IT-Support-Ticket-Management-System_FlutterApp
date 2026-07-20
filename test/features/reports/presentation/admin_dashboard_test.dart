import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:it_ticket_support_management/core/database/reference_data_service.dart';
import 'package:it_ticket_support_management/features/reports/application/services/i_report_service.dart';
import 'package:it_ticket_support_management/features/reports/domain/entities/feedback_summary_report.dart';
import 'package:it_ticket_support_management/features/reports/domain/entities/low_rating_feedback_report.dart';
import 'package:it_ticket_support_management/features/reports/domain/entities/processing_time_report.dart';
import 'package:it_ticket_support_management/features/reports/domain/entities/report_filter.dart';
import 'package:it_ticket_support_management/features/reports/domain/entities/sla_attention_report.dart';
import 'package:it_ticket_support_management/features/reports/domain/entities/staff_performance_report.dart';
import 'package:it_ticket_support_management/features/reports/domain/entities/ticket_volume_report.dart';
import 'package:it_ticket_support_management/features/reports/domain/entities/user_report.dart';
import 'package:it_ticket_support_management/features/reports/domain/entities/sla_summary_report.dart';
import 'package:it_ticket_support_management/features/reports/presentation/viewmodels/admin_dashboard_view_model.dart';
import 'package:it_ticket_support_management/features/reports/presentation/views/admin_dashboard_page.dart';
import 'package:provider/provider.dart';
import 'package:it_ticket_support_management/core/enums/sla_status.dart';

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
    expect(viewModel.slaSummary.currentlyBreached, 1);
  });

  test('exposes an SLA policy persistence failure', () async {
    final viewModel = AdminDashboardViewModel(
      reportService: _ReportServiceFake(),
      referenceDataService: ReferenceDataService(
        _SlaDatabaseFake(updateResult: 0),
      ),
    );

    final success = await viewModel.updateSlaPolicy(
      priorityId: 2,
      responseHours: 8,
      resolutionHours: 48,
    );

    expect(success, isFalse);
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, contains('Priority was not found'));
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
    expect(find.text('SLA performance'), findsOneWidget);
    expect(find.text('SLA attention required'), findsOneWidget);
    expect(find.text('Feedback quality'), findsOneWidget);
    expect(find.text('Alice User'), findsAtLeastNWidgets(1));
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
    await tester.scrollUntilVisible(
      find.text('Ticket overview'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ticket overview'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saves an SLA policy without using disposed controllers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final viewModel = AdminDashboardViewModel(
      reportService: _ReportServiceFake(),
      referenceDataService: ReferenceDataService(_SlaDatabaseFake()),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const MaterialApp(home: AdminDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Medium: 8h / 48h'));
    await tester.pumpAndSettle();
    expect(find.text('Medium SLA policy'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Medium SLA policy'), findsNothing);
    expect(find.text('SLA policy updated.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rejects non-numeric SLA policy values', (tester) async {
    await _pumpDashboardWithSla(tester);
    await tester.tap(find.text('Medium: 8h / 48h'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'not-a-number');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Enter valid SLA hours.'), findsOneWidget);
    expect(find.text('Medium SLA policy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rejects response SLA greater than resolution SLA', (
    tester,
  ) async {
    await _pumpDashboardWithSla(tester);
    await tester.tap(find.text('Medium: 8h / 48h'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '49');
    await tester.enterText(find.byType(TextField).last, '48');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(
      find.text(
        'Response SLA must be positive and cannot exceed resolution SLA.',
      ),
      findsOneWidget,
    );
    expect(find.text('Medium SLA policy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancels SLA policy dialog without controller exceptions', (
    tester,
  ) async {
    await _pumpDashboardWithSla(tester);
    await tester.tap(find.text('Medium: 8h / 48h'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Medium SLA policy'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDashboardWithSla(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 5000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: AdminDashboardViewModel(
        reportService: _ReportServiceFake(),
        referenceDataService: ReferenceDataService(_SlaDatabaseFake()),
      ),
      child: const MaterialApp(home: AdminDashboardPage()),
    ),
  );
  await tester.pumpAndSettle();
}

class _SlaDatabaseFake implements Database {
  _SlaDatabaseFake({this.updateResult = 1});

  final int updateResult;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #query) {
      final table = invocation.positionalArguments.first as String;
      if (table != 'priorities') {
        return Future<List<Map<String, Object?>>>.value(const []);
      }
      return Future<List<Map<String, Object?>>>.value([
        {
          'id': 2,
          'name': 'Medium',
          'level': 2,
          'slaHours': 48,
          'responseSlaHours': 8,
        },
      ]);
    }
    if (invocation.memberName == #update) {
      return Future<int>.value(updateResult);
    }
    return super.noSuchMethod(invocation);
  }
}

class _ReportServiceFake implements IReportService {
  String? lastStartDate;
  String? lastEndDate;

  void _recordRange(String startDate, String endDate) {
    lastStartDate = startDate;
    lastEndDate = endDate;
  }

  @override
  Future<SlaSummaryReport> getSlaSummaryReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async {
    _recordRange(startDate, endDate);
    return const SlaSummaryReport(
      totalActionable: 7,
      responseMet: 4,
      responseBreached: 1,
      resolutionMet: 2,
      resolutionBreached: 1,
      currentlyAtRisk: 1,
      currentlyBreached: 1,
      exempt: 1,
    );
  }

  @override
  Future<List<TicketVolumeReport>> getTicketVolumeReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async {
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
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async {
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
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async {
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
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async {
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

  @override
  Future<List<SlaAttentionReport>> getSlaAttentionReport({
    ReportFilter filter = const ReportFilter(),
  }) async => [
    SlaAttentionReport(
      ticketId: 12,
      title: 'VPN unavailable',
      priority: 'High',
      ticketStatus: 'Processing',
      slaStatus: SlaStatus.atRisk,
      createdAt: DateTime(2026, 7, 14),
      resolutionDueAt: DateTime.now().add(const Duration(hours: 2)),
      staffName: 'Support Staff',
      categoryName: 'Network Issue',
    ),
  ];

  @override
  Future<FeedbackSummaryReport> getFeedbackSummaryReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async {
    _recordRange(startDate, endDate);
    return const FeedbackSummaryReport(
      closedTickets: 4,
      totalFeedback: 3,
      averageRating: 3.7,
      lowRatingCount: 1,
      rating1Count: 0,
      rating2Count: 1,
      rating3Count: 0,
      rating4Count: 1,
      rating5Count: 1,
    );
  }

  @override
  Future<List<LowRatingFeedbackReport>> getLowRatingFeedbackReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async {
    _recordRange(startDate, endDate);
    return [
      LowRatingFeedbackReport(
        feedbackId: 1,
        ticketId: 12,
        ticketTitle: 'VPN unavailable',
        userName: 'Alice User',
        rating: 2,
        comment: 'Resolution was slow.',
        createdAt: DateTime(2026, 7, 15),
      ),
    ];
  }
}
