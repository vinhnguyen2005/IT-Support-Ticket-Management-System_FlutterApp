import '../../domain/entities/feedback_summary_report.dart';
import '../../domain/entities/low_rating_feedback_report.dart';
import '../../domain/entities/processing_time_report.dart';
import '../../domain/entities/report_filter.dart';
import '../../domain/entities/sla_attention_report.dart';
import '../../domain/entities/sla_summary_report.dart';
import '../../domain/entities/staff_performance_report.dart';
import '../../domain/entities/ticket_volume_report.dart';
import '../../domain/entities/user_report.dart';
import '../../domain/repositories/i_report_repository.dart';
import 'i_report_service.dart';

class ReportServiceImpl implements IReportService {
  const ReportServiceImpl({required this.repository});

  final IReportRepository repository;

  @override
  Future<SlaSummaryReport> getSlaSummaryReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) {
    _validateRange(startDate, endDate);
    return repository.getSlaSummaryReport(startDate, endDate, filter: filter);
  }

  @override
  Future<List<TicketVolumeReport>> getTicketVolumeReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) {
    _validateRange(startDate, endDate);
    return repository.getTicketVolumeReport(startDate, endDate, filter: filter);
  }

  @override
  Future<List<StaffPerformanceReport>> getStaffPerformanceReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) {
    _validateRange(startDate, endDate);
    return repository.getStaffPerformanceReport(
      startDate,
      endDate,
      filter: filter,
    );
  }

  @override
  Future<List<ProcessingTimeReport>> getProcessingTimeReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) {
    _validateRange(startDate, endDate);
    return repository.getProcessingTimeReport(
      startDate,
      endDate,
      filter: filter,
    );
  }

  @override
  Future<List<UserReport>> getUserReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) {
    _validateRange(startDate, endDate);
    return repository.getUserReport(startDate, endDate, filter: filter);
  }

  @override
  Future<List<SlaAttentionReport>> getSlaAttentionReport({
    ReportFilter filter = const ReportFilter(),
  }) => repository.getSlaAttentionReport(filter: filter);

  @override
  Future<FeedbackSummaryReport> getFeedbackSummaryReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) {
    _validateRange(startDate, endDate);
    return repository.getFeedbackSummaryReport(
      startDate,
      endDate,
      filter: filter,
    );
  }

  @override
  Future<List<LowRatingFeedbackReport>> getLowRatingFeedbackReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) {
    _validateRange(startDate, endDate);
    return repository.getLowRatingFeedbackReport(
      startDate,
      endDate,
      filter: filter,
    );
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
