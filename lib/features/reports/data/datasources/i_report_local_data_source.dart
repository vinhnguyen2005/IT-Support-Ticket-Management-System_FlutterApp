import '../../domain/entities/report_filter.dart';
import '../dtos/feedback_summary_report_dto.dart';
import '../dtos/low_rating_feedback_report_dto.dart';
import '../dtos/processing_time_report_dto.dart';
import '../dtos/sla_attention_report_dto.dart';
import '../dtos/sla_summary_report_dto.dart';
import '../dtos/staff_performance_report_dto.dart';
import '../dtos/ticket_volume_report_dto.dart';
import '../dtos/user_report_dto.dart';

abstract interface class IReportLocalDataSource {
  Future<List<TicketVolumeReportDto>> getTicketVolumeReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  });

  Future<List<StaffPerformanceReportDto>> getStaffPerformanceReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  });

  Future<List<ProcessingTimeReportDto>> getProcessingTimeReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  });

  Future<List<UserReportDto>> getUserReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  });

  Future<SlaSummaryReportDto> getSlaSummaryReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  });

  Future<List<SlaAttentionReportDto>> getSlaAttentionReport({
    ReportFilter filter = const ReportFilter(),
  });

  Future<FeedbackSummaryReportDto> getFeedbackSummaryReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  });

  Future<List<LowRatingFeedbackReportDto>> getLowRatingFeedbackReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  });
}
