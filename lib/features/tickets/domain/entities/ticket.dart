class Ticket {
  const Ticket({
    this.id,
    required this.title,
    required this.description,
    this.status = 'Open',
    this.priority = 'Medium',
    this.issueType = 'General',
    this.attachmentUrl,
    this.requestedId,
    this.assignedId,
    this.categoryId,
    this.solutionSummary,
    this.resolvedAt,
    required this.createdAt,
    this.updatedAt,
    this.createdByUserId,
    this.updatedByUserId,
    this.isDeleted = false,
  });

  final int? id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String issueType;
  final String? attachmentUrl;
  final int? requestedId;
  final int? assignedId;
  final int? categoryId;
  final String? solutionSummary;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? createdByUserId;
  final int? updatedByUserId;
  final bool isDeleted;

  bool get isResolved =>
      status.toLowerCase() == 'resolved' || status.toLowerCase() == 'closed';

  bool get isOpen => !isResolved && !isDeleted;
}
