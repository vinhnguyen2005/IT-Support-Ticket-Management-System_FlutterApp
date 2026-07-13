import 'package:flutter/foundation.dart';

import '../../application/services/i_report_service.dart';
import '../../domain/entities/processing_time_report.dart';
import '../../domain/entities/staff_performance_report.dart';
import '../../domain/entities/ticket_volume_report.dart';
import '../../domain/entities/user_report.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  AdminDashboardViewModel({required this.reportService});

  final IReportService reportService;

  bool _isLoading = false;
  String? _errorMessage;
  List<TicketVolumeReport> _volumeReports = const [];
  List<StaffPerformanceReport> _performanceReports = const [];
  List<ProcessingTimeReport> _processingTimeReports = const [];
  List<UserReport> _userReports = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TicketVolumeReport> get volumeReports => _volumeReports;
  List<StaffPerformanceReport> get performanceReports => _performanceReports;
  List<ProcessingTimeReport> get processingTimeReports =>
      _processingTimeReports;
  List<UserReport> get userReports => _userReports;

  int totalTicketsOverall = 0;
  int totalSubmittedOverall = 0;
  int totalAssignedOverall = 0;
  int totalProcessingOverall = 0;
  int totalResolvedOverall = 0;
  int totalClosedOverall = 0;
  int totalCancelledOverall = 0;
  int activeUsers = 0;
  int inactiveUsers = 0;

  int get totalOpenOverall =>
      totalSubmittedOverall + totalAssignedOverall + totalProcessingOverall;

  double get completionRate {
    final actionableTickets = totalTicketsOverall - totalCancelledOverall;
    if (actionableTickets <= 0) return 0;
    return (totalResolvedOverall + totalClosedOverall) / actionableTickets;
  }

  Future<void> loadDashboardData(String startDate, String endDate) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        reportService.getTicketVolumeReport(startDate, endDate),
        reportService.getStaffPerformanceReport(startDate, endDate),
        reportService.getProcessingTimeReport(startDate, endDate),
        reportService.getUserReport(startDate, endDate),
      ]);

      _volumeReports = results[0] as List<TicketVolumeReport>;
      _performanceReports = results[1] as List<StaffPerformanceReport>;
      _processingTimeReports = results[2] as List<ProcessingTimeReport>;
      _userReports = results[3] as List<UserReport>;
      _calculateTotals();
    } catch (error) {
      _errorMessage = 'Failed to load report data: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateTotals() {
    totalTicketsOverall = 0;
    totalSubmittedOverall = 0;
    totalAssignedOverall = 0;
    totalProcessingOverall = 0;
    totalResolvedOverall = 0;
    totalClosedOverall = 0;
    totalCancelledOverall = 0;

    for (final report in _volumeReports) {
      totalTicketsOverall += report.totalTickets;
      totalSubmittedOverall += report.submittedTickets;
      totalAssignedOverall += report.assignedTickets;
      totalProcessingOverall += report.processingTickets;
      totalResolvedOverall += report.resolvedTickets;
      totalClosedOverall += report.closedTickets;
      totalCancelledOverall += report.cancelledTickets;
    }

    activeUsers = _userReports.where((user) => user.isActive).length;
    inactiveUsers = _userReports.length - activeUsers;
  }
}
