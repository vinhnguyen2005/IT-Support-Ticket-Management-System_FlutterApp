import '../../domain/entities/feedback_summary_report.dart';
import '../../domain/entities/low_rating_feedback_report.dart';
import '../../domain/entities/processing_time_report.dart';
import '../../domain/entities/sla_attention_report.dart';
import '../../domain/entities/staff_performance_report.dart';
import '../../domain/entities/ticket_volume_report.dart';
import '../../domain/entities/user_report.dart';
import '../dtos/feedback_summary_report_dto.dart';
import '../dtos/low_rating_feedback_report_dto.dart';
import '../dtos/processing_time_report_dto.dart';
import '../dtos/sla_attention_report_dto.dart';
import '../dtos/staff_performance_report_dto.dart';
import '../dtos/ticket_volume_report_dto.dart';
import '../dtos/user_report_dto.dart';

extension TicketVolumeReportMapper on TicketVolumeReportDto {
  TicketVolumeReport toEntity() => TicketVolumeReport(
    date: date,
    totalTickets: totalTickets,
    submittedTickets: submittedTickets,
    assignedTickets: assignedTickets,
    processingTickets: processingTickets,
    resolvedTickets: resolvedTickets,
    closedTickets: closedTickets,
    cancelledTickets: cancelledTickets,
  );
}

extension TicketVolumeReportListMapper on List<TicketVolumeReportDto> {
  List<TicketVolumeReport> toEntityList() =>
      map((dto) => dto.toEntity()).toList(growable: false);
}

extension StaffPerformanceReportMapper on StaffPerformanceReportDto {
  StaffPerformanceReport toEntity() => StaffPerformanceReport(
    staffId: staffId,
    staffName: staffName,
    assignedTickets: assignedTickets,
    resolvedTickets: resolvedTickets,
  );
}

extension StaffPerformanceReportListMapper on List<StaffPerformanceReportDto> {
  List<StaffPerformanceReport> toEntityList() =>
      map((dto) => dto.toEntity()).toList(growable: false);
}

extension ProcessingTimeReportMapper on ProcessingTimeReportDto {
  ProcessingTimeReport toEntity() => ProcessingTimeReport(
    categoryName: categoryName,
    completedTickets: completedTickets,
    averageHours: averageHours,
  );
}

extension ProcessingTimeReportListMapper on List<ProcessingTimeReportDto> {
  List<ProcessingTimeReport> toEntityList() =>
      map((dto) => dto.toEntity()).toList(growable: false);
}

extension UserReportMapper on UserReportDto {
  UserReport toEntity() => UserReport(
    userId: userId,
    fullName: fullName,
    username: username,
    role: role,
    departmentName: departmentName,
    isActive: isActive,
    lastLoginAt: lastLoginAt,
    createdTickets: createdTickets,
    completedTickets: completedTickets,
  );
}

extension UserReportListMapper on List<UserReportDto> {
  List<UserReport> toEntityList() =>
      map((dto) => dto.toEntity()).toList(growable: false);
}

extension SlaAttentionReportMapper on SlaAttentionReportDto {
  SlaAttentionReport toEntity() => SlaAttentionReport(
    ticketId: ticketId,
    title: title,
    priority: priority,
    ticketStatus: ticketStatus,
    slaStatus: slaStatus,
    createdAt: createdAt,
    resolutionDueAt: resolutionDueAt,
    staffName: staffName,
    categoryName: categoryName,
  );
}

extension SlaAttentionReportListMapper on List<SlaAttentionReportDto> {
  List<SlaAttentionReport> toEntityList() =>
      map((dto) => dto.toEntity()).toList(growable: false);
}

extension FeedbackSummaryReportMapper on FeedbackSummaryReportDto {
  FeedbackSummaryReport toEntity() => FeedbackSummaryReport(
    closedTickets: closedTickets,
    totalFeedback: totalFeedback,
    averageRating: averageRating,
    lowRatingCount: lowRatingCount,
    rating1Count: rating1Count,
    rating2Count: rating2Count,
    rating3Count: rating3Count,
    rating4Count: rating4Count,
    rating5Count: rating5Count,
  );
}

extension LowRatingFeedbackReportMapper on LowRatingFeedbackReportDto {
  LowRatingFeedbackReport toEntity() => LowRatingFeedbackReport(
    feedbackId: feedbackId,
    ticketId: ticketId,
    ticketTitle: ticketTitle,
    userName: userName,
    rating: rating,
    comment: comment,
    createdAt: createdAt,
  );
}

extension LowRatingFeedbackReportListMapper
    on List<LowRatingFeedbackReportDto> {
  List<LowRatingFeedbackReport> toEntityList() =>
      map((dto) => dto.toEntity()).toList(growable: false);
}
