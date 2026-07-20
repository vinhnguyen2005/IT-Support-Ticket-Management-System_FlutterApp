import '../entities/feedback_summary_report.dart';
import '../entities/low_rating_feedback_report.dart';
import '../entities/processing_time_report.dart';
import '../entities/report_filter.dart';
import '../entities/sla_attention_report.dart';
import '../entities/sla_summary_report.dart';
import '../entities/staff_performance_report.dart';
import '../entities/ticket_volume_report.dart';
import '../entities/user_report.dart';

abstract interface class IReportRepository {
  Future<List<TicketVolumeReport>> getTicketVolumeReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  });

  Future<List<StaffPerformanceReport>> getStaffPerformanceReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  });

  Future<List<ProcessingTimeReport>> getProcessingTimeReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  });

  Future<List<UserReport>> getUserReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  });

  Future<SlaSummaryReport> getSlaSummaryReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  });

  Future<List<SlaAttentionReport>> getSlaAttentionReport({
    ReportFilter filter = const ReportFilter(),
  });

  Future<FeedbackSummaryReport> getFeedbackSummaryReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  });

  Future<List<LowRatingFeedbackReport>> getLowRatingFeedbackReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  });
}
