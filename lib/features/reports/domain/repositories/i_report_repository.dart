import '../entities/processing_time_report.dart';
import '../entities/staff_performance_report.dart';
import '../entities/ticket_volume_report.dart';
import '../entities/user_report.dart';

abstract interface class IReportRepository {
  Future<List<TicketVolumeReport>> getTicketVolumeReport(
    String startDate,
    String endDate,
  );

  Future<List<StaffPerformanceReport>> getStaffPerformanceReport(
    String startDate,
    String endDate,
  );

  Future<List<ProcessingTimeReport>> getProcessingTimeReport(
    String startDate,
    String endDate,
  );

  Future<List<UserReport>> getUserReport(String startDate, String endDate);
}
