import 'package:flutter/foundation.dart';

import '../../application/services/i_department_service.dart';
import '../../domain/entities/department.dart';

class DepartmentViewModel extends ChangeNotifier {
  DepartmentViewModel(this._service);

  final IDepartmentService _service;

  bool isLoading = false;
  String? errorMessage;
  List<Department> departments = const [];

  Future<void> loadDepartments() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      departments = await _service.getDepartments();
    } catch (error) {
      errorMessage = 'Unable to load departments: $error';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveDepartment({
    int? id,
    required String name,
    String? description,
    required bool isActive,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (id == null) {
        await _service.createDepartment(
          name: name,
          description: description,
          isActive: isActive,
        );
      } else {
        await _service.updateDepartment(
          id: id,
          name: name,
          description: description,
          isActive: isActive,
        );
      }
      departments = await _service.getDepartments();
      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
