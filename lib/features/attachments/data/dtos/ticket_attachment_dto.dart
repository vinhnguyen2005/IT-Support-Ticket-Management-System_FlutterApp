class TicketAttachmentDto {
  const TicketAttachmentDto({
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

  factory TicketAttachmentDto.fromMap(Map<String, Object?> map) {
    return TicketAttachmentDto(
      id: _readInt(map['id']),
      ticketId: _readInt(map['ticketId']) ?? 0,
      uploadedByUserId: _readInt(map['uploadedByUserId']) ?? 0,
      fileName: (map['fileName'] as String?) ?? '',
      filePath: (map['filePath'] as String?) ?? '',
      contentType: map['contentType'] as String?,
      fileSizeBytes: _readInt(map['fileSizeBytes']),
      createdAt: _readDateTime(map['createdAt']) ?? DateTime.now(),
      uploaderName: map['uploaderName'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'uploadedByUserId': uploadedByUserId,
      'fileName': fileName,
      'filePath': filePath,
      'contentType': contentType,
      'fileSizeBytes': fileSizeBytes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static int? _readInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _readDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
