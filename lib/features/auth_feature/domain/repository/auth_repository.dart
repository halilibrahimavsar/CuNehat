import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signInWithGoogle();
  Future<void> signOut();
  Stream<UserEntity?> get userChanges; // Auth state changes
}
