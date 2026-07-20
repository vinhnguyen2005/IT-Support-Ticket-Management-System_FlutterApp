import '../../domain/entities/department.dart';
import '../dtos/department_dto.dart';

class DepartmentMapper {
  const DepartmentMapper();

  Department toEntity(DepartmentDto dto) => Department(
    id: dto.id,
    name: dto.name,
    description: dto.description,
    isActive: dto.isActive,
    createdAt: dto.createdAt,
    updatedAt: dto.updatedAt,
  );
}
