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
import '../datasources/i_report_local_data_source.dart';
import '../mappers/report_mapper.dart';

class ReportRepositoryImpl implements IReportRepository {
  const ReportRepositoryImpl({required this.localDataSource});

  final IReportLocalDataSource localDataSource;

  @override
  Future<SlaSummaryReport> getSlaSummaryReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async => (await localDataSource.getSlaSummaryReport(
    startDate,
    endDate,
    filter: filter,
  )).toEntity();

  @override
  Future<List<TicketVolumeReport>> getTicketVolumeReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async => (await localDataSource.getTicketVolumeReport(
    startDate,
    endDate,
    filter: filter,
  )).toEntityList();

  @override
  Future<List<StaffPerformanceReport>> getStaffPerformanceReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async => (await localDataSource.getStaffPerformanceReport(
    startDate,
    endDate,
    filter: filter,
  )).toEntityList();

  @override
  Future<List<ProcessingTimeReport>> getProcessingTimeReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async => (await localDataSource.getProcessingTimeReport(
    startDate,
    endDate,
    filter: filter,
  )).toEntityList();

  @override
  Future<List<UserReport>> getUserReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async => (await localDataSource.getUserReport(
    startDate,
    endDate,
    filter: filter,
  )).toEntityList();

  @override
  Future<List<SlaAttentionReport>> getSlaAttentionReport({
    ReportFilter filter = const ReportFilter(),
  }) async => (await localDataSource.getSlaAttentionReport(
    filter: filter,
  )).toEntityList();

  @override
  Future<FeedbackSummaryReport> getFeedbackSummaryReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async => (await localDataSource.getFeedbackSummaryReport(
    startDate,
    endDate,
    filter: filter,
  )).toEntity();

  @override
  Future<List<LowRatingFeedbackReport>> getLowRatingFeedbackReport(
    String startDate,
    String endDate, {
    ReportFilter filter = const ReportFilter(),
  }) async => (await localDataSource.getLowRatingFeedbackReport(
    startDate,
    endDate,
    filter: filter,
  )).toEntityList();
}
