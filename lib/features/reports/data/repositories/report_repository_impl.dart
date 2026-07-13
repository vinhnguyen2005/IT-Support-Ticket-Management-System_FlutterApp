import '../../domain/entities/processing_time_report.dart';
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
  Future<List<TicketVolumeReport>> getTicketVolumeReport(
    String startDate,
    String endDate,
  ) async {
    final dtos = await localDataSource.getTicketVolumeReport(
      startDate,
      endDate,
    );
    return dtos.toEntityList();
  }

  @override
  Future<List<StaffPerformanceReport>> getStaffPerformanceReport(
    String startDate,
    String endDate,
  ) async {
    final dtos = await localDataSource.getStaffPerformanceReport(
      startDate,
      endDate,
    );
    return dtos.toEntityList();
  }

  @override
  Future<List<ProcessingTimeReport>> getProcessingTimeReport(
    String startDate,
    String endDate,
  ) async {
    final dtos = await localDataSource.getProcessingTimeReport(
      startDate,
      endDate,
    );
    return dtos.toEntityList();
  }

  @override
  Future<List<UserReport>> getUserReport(
    String startDate,
    String endDate,
  ) async {
    final dtos = await localDataSource.getUserReport(startDate, endDate);
    return dtos.toEntityList();
  }
}
