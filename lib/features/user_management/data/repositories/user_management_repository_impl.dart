import '../../../../core/security/password_hasher.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/repositories/i_user_management_repository.dart';
import '../datasources/i_user_local_data_source.dart';
import '../dtos/create_user_request_dto.dart';
import '../dtos/update_user_request_dto.dart';
import '../mappers/user_mapper.dart';

class UserManagementRepositoryImpl implements IUserManagementRepository {
  const UserManagementRepositoryImpl({
    required IUserLocalDataSource localDataSource,
    required UserManagementMapper mapper,
  }) : _localDataSource = localDataSource,
       _mapper = mapper;

  final IUserLocalDataSource _localDataSource;
  final UserManagementMapper _mapper;

  @override
  Future<List<ManagedUser>> getUsers() async {
    final users = await _localDataSource.getUsers();
    return users.map(_mapper.mapToEntity).toList();
  }

  @override
  Future<ManagedUser?> getUserById(int id) async {
    final user = await _localDataSource.getUserById(id);
    if (user == null) {
      return null;
    }

    return _mapper.mapToEntity(user);
  }

  @override
  Future<void> createUser({
    required String fullName,
    required String username,
    required String email,
    required String temporaryPassword,
    required String role,
    int? departmentId,
    String? phoneNumber,
  }) async {
    await _localDataSource.createUser(
      CreateUserRequestDto(
        fullName: fullName,
        username: username,
        email: email,
        temporaryPasswordHash: PasswordHasher.hash(temporaryPassword),
        role: role,
        departmentId: departmentId,
        phoneNumber: phoneNumber,
      ),
    );
  }

  @override
  Future<void> updateUser({
    required int id,
    required String fullName,
    required String email,
    required String role,
    int? departmentId,
    String? phoneNumber,
    required bool isActive,
  }) async {
    await _localDataSource.updateUser(
      UpdateUserRequestDto(
        id: id,
        fullName: fullName,
        email: email,
        role: role,
        departmentId: departmentId,
        phoneNumber: phoneNumber,
        isActive: isActive,
      ),
    );
  }

  @override
  Future<void> setUserActive({required int id, required bool isActive}) async {
    await _localDataSource.setUserActive(id: id, isActive: isActive);
  }

  @override
  Future<void> resetTemporaryPassword({
    required int id,
    required String temporaryPassword,
  }) async {
    await _localDataSource.resetTemporaryPassword(
      id: id,
      temporaryPasswordHash: PasswordHasher.hash(temporaryPassword),
    );
  }
}
