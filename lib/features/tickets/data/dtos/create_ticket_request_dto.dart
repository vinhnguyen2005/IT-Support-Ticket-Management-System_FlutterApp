class CreateTicketRequestDto {
  const CreateTicketRequestDto({
    required this.title,
    required this.description,
    this.issueType = 'General',
    this.priority = 'Medium',
    this.status = 'Open',
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
