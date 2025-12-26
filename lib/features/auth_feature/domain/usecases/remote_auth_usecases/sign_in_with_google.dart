import 'package:cunehat/features/auth_feature/domain/repository/auth_repository.dart';
import '../../entities/user_entity.dart';

class SignInWithGoogle {
  final AuthRepository repository;

  SignInWithGoogle(this.repository);

  Future<UserEntity> call() {
    return repository.signInWithGoogle();
  }
}
