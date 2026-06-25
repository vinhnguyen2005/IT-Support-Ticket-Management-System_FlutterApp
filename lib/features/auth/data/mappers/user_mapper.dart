import '../../domain/entities/user.dart';
import '../dtos/user_dto.dart';

class UserMapper {
  const UserMapper();

  User mapToEntity(UserDto dto) {
    return User(
      id: dto.id,
      fullName: dto.fullName,
      username: dto.username,
      email: dto.email,
      role: dto.role,
      departmentId: dto.departmentId,
      phoneNumber: dto.phoneNumber,
      avatarUrl: dto.avatarUrl,
      isActive: dto.isActive,
      mustChangePassword: dto.mustChangePassword,
      lastLoginAt: dto.lastLoginAt,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }
}
