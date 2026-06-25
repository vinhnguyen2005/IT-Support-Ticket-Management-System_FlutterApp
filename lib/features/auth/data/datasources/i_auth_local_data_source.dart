import '../dtos/login_request_dto.dart';
import '../dtos/login_response_dto.dart';
import '../dtos/user_dto.dart';

abstract interface class IAuthLocalDataSource {
  Future<LoginResponseDto> login(LoginRequestDto request);

  Future<void> logout();

  Future<UserDto?> getCurrentUser();

  Future<void> saveCurrentUser(UserDto user);

  Future<void> changePassword({
    required int userId,
    required String newPasswordHash,
  });
}
