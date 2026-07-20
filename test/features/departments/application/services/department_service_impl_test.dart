import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/core/errors/exceptions.dart';
import 'package:it_ticket_support_management/features/departments/application/services/department_service_impl.dart';
import 'package:it_ticket_support_management/features/departments/domain/entities/department.dart';
import 'package:it_ticket_support_management/features/departments/domain/repositories/i_department_repository.dart';

void main() {
  late _DepartmentRepositoryFake repository;
  late DepartmentServiceImpl service;

  setUp(() {
    repository = _DepartmentRepositoryFake();
    service = DepartmentServiceImpl(repository);
  });

  test('create trims values and rejects a duplicate name', () async {
    await service.createDepartment(
      name: '  Infrastructure  ',
      description: '  Core systems  ',
      isActive: true,
    );

    expect(repository.createdName, 'Infrastructure');
    expect(repository.createdDescription, 'Core systems');

    repository.match = Department(
      id: 1,
      name: 'Infrastructure',
      isActive: true,
      createdAt: DateTime(2026),
    );
    expect(
      () => service.createDepartment(name: 'Infrastructure', isActive: true),
      throwsA(isA<AppException>()),
    );
  });

  test('cannot deactivate a department with active references', () async {
    repository.activeReferences = 2;

    expect(
      () => service.updateDepartment(id: 1, name: 'IT', isActive: false),
      throwsA(
        isA<AppException>().having(
          (error) => error.toString(),
          'message',
          contains('active users and categories'),
        ),
      ),
    );
    expect(repository.updatedId, isNull);
  });

  test('updates an active department when validation succeeds', () async {
    await service.updateDepartment(
      id: 4,
      name: '  Service Desk ',
      description: ' ',
      isActive: true,
    );

    expect(repository.updatedId, 4);
    expect(repository.updatedName, 'Service Desk');
    expect(repository.updatedDescription, isNull);
    expect(repository.updatedIsActive, isTrue);
  });
}

class _DepartmentRepositoryFake implements IDepartmentRepository {
  Department? match;
  int activeReferences = 0;
  String? createdName;
  String? createdDescription;
  int? updatedId;
  String? updatedName;
  String? updatedDescription;
  bool? updatedIsActive;

  @override
  Future<int> countActiveReferences(int departmentId) async => activeReferences;

  @override
  Future<void> createDepartment({
    required String name,
    String? description,
    required bool isActive,
  }) async {
    createdName = name;
    createdDescription = description;
  }

  @override
  Future<Department?> findByName(String name, {int? excludeId}) async => match;

  @override
  Future<List<Department>> getDepartments() async => const [];

  @override
  Future<void> updateDepartment({
    required int id,
    required String name,
    String? description,
    required bool isActive,
  }) async {
    updatedId = id;
    updatedName = name;
    updatedDescription = description;
    updatedIsActive = isActive;
  }
}
