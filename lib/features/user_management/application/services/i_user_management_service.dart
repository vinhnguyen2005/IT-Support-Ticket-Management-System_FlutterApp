import '../../domain/entities/managed_user.dart';

abstract interface class IUserManagementService {
  Future<List<ManagedUser>> getUsers();

  Future<void> createUser({
    required String fullName,
    required String username,
    required String email,
    required String temporaryPassword,
    required String role,
    int? departmentId,
    String? phoneNumber,
  });

  Future<void> updateUser({
    required int id,
    required String fullName,
    required String email,
    required String role,
    int? departmentId,
    String? phoneNumber,
    required bool isActive,
  });

  Future<void> setUserActive({required int id, required bool isActive});

  Future<void> resetTemporaryPassword({
    required int id,
    required String temporaryPassword,
  });
}
