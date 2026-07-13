import '../../domain/entities/processing_time_report.dart';
import '../../domain/entities/staff_performance_report.dart';
import '../../domain/entities/ticket_volume_report.dart';
import '../../domain/entities/user_report.dart';

abstract interface class IReportService {
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
