import 'package:cunehat/core/error/auth_exceptions.dart';
import 'package:cunehat/features/auth_feature/domain/repository/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../datasources/auth_remote_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserEntity> signInWithGoogle() async {
    final UserCredential credential = await remoteDataSource.googleLogin();
    if (credential.user == null) {
      throw GenericAuthException(cause: 'Google sign-in failed');
    }
    final User firebaseUser = credential.user!;
    return UserEntity(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName,
      email: firebaseUser.email,
      photoUrl: firebaseUser.photoURL,
    );
  }

  @override
  Future<void> signOut() async {
    await remoteDataSource.logOut();
  }

  @override
  Stream<UserEntity?> get userChanges {
    return remoteDataSource.userChanges.map((firebaseUser) {
      if (firebaseUser == null) return null;
      return UserEntity(
        uid: firebaseUser.uid,
        displayName: firebaseUser.displayName,
        email: firebaseUser.email,
        photoUrl: firebaseUser.photoURL,
      );
    });
  }
}
