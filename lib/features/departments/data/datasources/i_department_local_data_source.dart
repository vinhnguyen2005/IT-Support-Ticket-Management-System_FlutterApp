import '../dtos/department_dto.dart';

abstract interface class IDepartmentLocalDataSource {
  Future<List<DepartmentDto>> getDepartments();

  Future<DepartmentDto?> findByName(String name, {int? excludeId});

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
