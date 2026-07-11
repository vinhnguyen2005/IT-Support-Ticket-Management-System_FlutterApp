import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../../application/services/i_attachment_service.dart';
import '../../domain/entities/ticket_attachment.dart';

enum AttachmentStatus { initial, loading, success, failure }

class AttachmentViewModel extends ChangeNotifier {
  AttachmentViewModel(this._service);

  final IAttachmentService _service;

  AttachmentStatus _status = AttachmentStatus.initial;
  String? _errorMessage;
  List<TicketAttachment> _attachments = [];

  AttachmentStatus get status => _status;
  bool get isLoading => _status == AttachmentStatus.loading;
  String? get errorMessage => _errorMessage;
  List<TicketAttachment> get attachments => List.unmodifiable(_attachments);

  Future<void> loadAttachments(int ticketId) async {
    _status = AttachmentStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _attachments = await _service.getAttachmentsByTicketId(ticketId);
      _status = AttachmentStatus.success;
    } catch (e) {
      _status = AttachmentStatus.failure;
      _errorMessage = 'Failed to load attachments: $e';
    }

    notifyListeners();
  }

  Future<bool> addAttachmentFromFile({
    required int ticketId,
    required int uploadedByUserId,
    required File file,
    String? contentType,
  }) async {
    _status = AttachmentStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final fileName = path.basename(file.path);
      final filePath = file.path;
      final fileSize = await file.length();

      final attachment = await _service.addAttachment(
        ticketId: ticketId,
        uploadedByUserId: uploadedByUserId,
        fileName: fileName,
        filePath: filePath,
        contentType: contentType,
        fileSizeBytes: fileSize,
      );

      _attachments = [..._attachments, attachment];
      _status = AttachmentStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AttachmentStatus.failure;
      _errorMessage = 'Failed to add attachment: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAttachment(int id) async {
    _status = AttachmentStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteAttachment(id);
      _attachments = _attachments.where((a) => a.id != id).toList();
      _status = AttachmentStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AttachmentStatus.failure;
      _errorMessage = 'Failed to delete attachment: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
