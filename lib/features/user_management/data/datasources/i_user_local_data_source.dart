import '../dtos/create_user_request_dto.dart';
import '../dtos/update_user_request_dto.dart';
import '../dtos/user_dto.dart';

abstract interface class IUserLocalDataSource {
  Future<List<UserDto>> getUsers();

  Future<UserDto?> getUserById(int id);

  Future<int> createUser(CreateUserRequestDto request);

  Future<int> updateUser(UpdateUserRequestDto request);

  Future<int> setUserActive({required int id, required bool isActive});

  Future<int> resetTemporaryPassword({
    required int id,
    required String temporaryPasswordHash,
  });
}
