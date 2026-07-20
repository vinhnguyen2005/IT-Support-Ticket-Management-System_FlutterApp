class TicketAttachment {
  const TicketAttachment({
    this.id,
    required this.ticketId,
    required this.uploadedByUserId,
    required this.fileName,
    required this.filePath,
    this.contentType,
    this.fileSizeBytes,
    required this.createdAt,
    this.uploaderName,
  });

  final int? id;
  final int ticketId;
  final int uploadedByUserId;
  final String fileName;
  final String filePath;
  final String? contentType;
  final int? fileSizeBytes;
  final DateTime createdAt;
  final String? uploaderName;

  String get fileSizeFormatted {
    if (fileSizeBytes == null) return 'Unknown';
    if (fileSizeBytes! < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes! < 1024 * 1024) {
      return '${(fileSizeBytes! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage => contentType != null && contentType!.startsWith('image/');

  bool get isPdf => contentType == 'application/pdf';
}
