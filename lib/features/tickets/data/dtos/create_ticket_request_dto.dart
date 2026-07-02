import '../../../../core/enums/issue_type.dart';
import '../../../../core/enums/priority_level.dart';
import '../../../../core/enums/ticket_status.dart';

class CreateTicketRequestDto {
  const CreateTicketRequestDto({
    required this.title,
    required this.description,
    this.issueType = IssueType.defaultValue,
    this.priority = PriorityLevel.defaultValue,
    this.status = TicketStatus.defaultValue,
    this.attachmentUrl,
    this.categoryId,
    this.requestedId,
  });

  final String title;
  final String description;
  final String issueType;
  final String priority;
  final String status;
  final String? attachmentUrl;
  final int? categoryId;
  final int? requestedId;

  Map<String, Object?> toMap(DateTime now) {
    return {
      'title': title,
      'description': description,
      'issueType': issueType,
      'priority': priority,
      'status': status,
      'createdByUserId': requestedId,
      'categoryId': categoryId,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
  }

  Map<String, Object?> toJson() {
    return {
      'title': title,
      'description': description,
      'issueType': issueType,
      'priority': priority,
      'status': status,
      'attachmentUrl': attachmentUrl,
      'categoryId': categoryId,
      'requestedId': requestedId,
    };
  }
}
