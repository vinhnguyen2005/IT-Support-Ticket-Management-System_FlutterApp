import '../entities/department.dart';

abstract interface class IDepartmentRepository {
  Future<List<Department>> getDepartments();

  Future<Department?> findByName(String name, {int? excludeId});

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

  Future<int> countActiveReferences(int departmentId);
}
