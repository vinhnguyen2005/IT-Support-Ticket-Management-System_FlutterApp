import 'package:flutter/foundation.dart';

import '../../../../core/database/reference_data_service.dart';
import '../../application/services/i_user_management_service.dart';

class UpdateUserViewModel extends ChangeNotifier {
  UpdateUserViewModel(this._service, [this._referenceDataService]);

  final IUserManagementService _service;
  final ReferenceDataService? _referenceDataService;

  bool _isLoading = false;
  String? _errorMessage;
  List<DepartmentReference> _departments = const [];

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  List<DepartmentReference> get departments => List.unmodifiable(_departments);

  Future<void> loadDepartments() async {
    final service = _referenceDataService;
    if (service == null) {
      return;
    }

    try {
      _departments = await service.getActiveDepartments();
    } catch (error) {
      _errorMessage = 'Unable to load departments: $error';
    }
    notifyListeners();
  }

  Future<bool> updateUser({
    required int id,
    required String fullName,
    required String email,
    required String role,
    int? departmentId,
    String? phoneNumber,
    required bool isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateUser(
        id: id,
        fullName: fullName,
        email: email,
        role: role,
        departmentId: departmentId,
        phoneNumber: phoneNumber,
        isActive: isActive,
      );
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
