import '../../domain/entities/processing_time_report.dart';
import '../../domain/entities/staff_performance_report.dart';
import '../../domain/entities/ticket_volume_report.dart';
import '../../domain/entities/user_report.dart';
import '../../domain/repositories/i_report_repository.dart';
import 'i_report_service.dart';

class ReportServiceImpl implements IReportService {
  const ReportServiceImpl({required this.repository});

  final IReportRepository repository;

  @override
  Future<List<TicketVolumeReport>> getTicketVolumeReport(
    String startDate,
    String endDate,
  ) {
    _validateRange(startDate, endDate);
    return repository.getTicketVolumeReport(startDate, endDate);
  }

  @override
  Future<List<StaffPerformanceReport>> getStaffPerformanceReport(
    String startDate,
    String endDate,
  ) {
    _validateRange(startDate, endDate);
    return repository.getStaffPerformanceReport(startDate, endDate);
  }

  @override
  Future<List<ProcessingTimeReport>> getProcessingTimeReport(
    String startDate,
    String endDate,
  ) {
    _validateRange(startDate, endDate);
    return repository.getProcessingTimeReport(startDate, endDate);
  }

  @override
  Future<List<UserReport>> getUserReport(String startDate, String endDate) {
    _validateRange(startDate, endDate);
    return repository.getUserReport(startDate, endDate);
  }

  void _validateRange(String startDate, String endDate) {
    final start = DateTime.tryParse(startDate);
    final end = DateTime.tryParse(endDate);
    if (start == null || end == null) {
      throw ArgumentError('A valid start date and end date are required.');
    }
    if (start.isAfter(end)) {
      throw ArgumentError('Start date cannot be after end date.');
    }
  }
}
