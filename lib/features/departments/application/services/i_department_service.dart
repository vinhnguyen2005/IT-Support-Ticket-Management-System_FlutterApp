import '../../domain/entities/department.dart';

abstract interface class IDepartmentService {
  Future<List<Department>> getDepartments();

  Future<void> createDepartment({
    required String name,
    String? description,
    required bool isActive,
  });

  Future<void> updateDepartment({
    required int id,
    required String name,
    String? description,
    required bool isActive,
  });
}
