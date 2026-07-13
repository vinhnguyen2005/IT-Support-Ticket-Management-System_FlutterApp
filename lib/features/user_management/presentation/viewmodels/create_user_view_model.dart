import 'package:flutter/foundation.dart';

import '../../../../core/database/reference_data_service.dart';
import '../../application/services/i_user_management_service.dart';

class CreateUserViewModel extends ChangeNotifier {
  CreateUserViewModel(this._service, [this._referenceDataService]);

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

  Future<bool> createUser({
    required String fullName,
    required String username,
    required String email,
    required String temporaryPassword,
    required String role,
    int? departmentId,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createUser(
        fullName: fullName,
        username: username,
        email: email,
        temporaryPassword: temporaryPassword,
        role: role,
        departmentId: departmentId,
        phoneNumber: phoneNumber,
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
