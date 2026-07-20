import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/department.dart';
import '../../domain/repositories/i_department_repository.dart';
import 'i_department_service.dart';

class DepartmentServiceImpl implements IDepartmentService {
  const DepartmentServiceImpl(this._repository);

  final IDepartmentRepository _repository;

  @override
  Future<List<Department>> getDepartments() => _repository.getDepartments();

  @override
  Future<void> createDepartment({
    required String name,
    String? description,
    required bool isActive,
  }) async {
    final normalizedName = _validateName(name);
    if (await _repository.findByName(normalizedName) != null) {
      throw const AppException('A department with this name already exists.');
    }
    await _repository.createDepartment(
      name: normalizedName,
      description: _normalizeOptional(description),
      isActive: isActive,
    );
  }

  @override
  Future<void> updateDepartment({
    required int id,
    required String name,
    String? description,
    required bool isActive,
  }) async {
    if (id <= 0) throw const AppException('Department id is required.');
    final normalizedName = _validateName(name);
    if (await _repository.findByName(normalizedName, excludeId: id) != null) {
      throw const AppException('A department with this name already exists.');
    }
    if (!isActive && await _repository.countActiveReferences(id) > 0) {
      throw const AppException(
        'Move or deactivate active users and categories before disabling this department.',
      );
    }
    await _repository.updateDepartment(
      id: id,
      name: normalizedName,
      description: _normalizeOptional(description),
      isActive: isActive,
    );
  }

  String _validateName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw const AppException('Department name is required.');
    }
    if (normalized.length > 100) {
      throw const AppException('Department name cannot exceed 100 characters.');
    }
    return normalized;
  }

  String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
