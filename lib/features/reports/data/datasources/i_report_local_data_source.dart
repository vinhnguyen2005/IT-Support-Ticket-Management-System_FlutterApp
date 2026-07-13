import '../dtos/processing_time_report_dto.dart';
import '../dtos/staff_performance_report_dto.dart';
import '../dtos/ticket_volume_report_dto.dart';
import '../dtos/user_report_dto.dart';

abstract interface class IReportLocalDataSource {
  Future<List<TicketVolumeReportDto>> getTicketVolumeReport(
    String startDate,
    String endDate,
  );

  Future<List<StaffPerformanceReportDto>> getStaffPerformanceReport(
    String startDate,
    String endDate,
  );

  Future<List<ProcessingTimeReportDto>> getProcessingTimeReport(
    String startDate,
    String endDate,
  );

  Future<List<UserReportDto>> getUserReport(String startDate, String endDate);
}
