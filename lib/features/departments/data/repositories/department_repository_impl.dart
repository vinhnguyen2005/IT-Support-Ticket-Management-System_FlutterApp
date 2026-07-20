import '../../domain/entities/department.dart';
import '../../domain/repositories/i_department_repository.dart';
import '../datasources/i_department_local_data_source.dart';
import '../mappers/department_mapper.dart';

class DepartmentRepositoryImpl implements IDepartmentRepository {
  const DepartmentRepositoryImpl({
    required this.localDataSource,
    this.mapper = const DepartmentMapper(),
  });

  final IDepartmentLocalDataSource localDataSource;
  final DepartmentMapper mapper;

  @override
  Future<List<Department>> getDepartments() async =>
      (await localDataSource.getDepartments())
          .map(mapper.toEntity)
          .toList(growable: false);

  @override
  Future<Department?> findByName(String name, {int? excludeId}) async {
    final dto = await localDataSource.findByName(name, excludeId: excludeId);
    return dto == null ? null : mapper.toEntity(dto);
  }

  @override
  Future<void> createDepartment({
    required String name,
    String? description,
    required bool isActive,
  }) => localDataSource.createDepartment(
    name: name,
    description: description,
    isActive: isActive,
  );

  @override
  Future<void> updateDepartment({
    required int id,
    required String name,
    String? description,
    required bool isActive,
  }) => localDataSource.updateDepartment(
    id: id,
    name: name,
    description: description,
    isActive: isActive,
  );

  @override
  Future<int> countActiveReferences(int departmentId) =>
      localDataSource.countActiveReferences(departmentId);
}
