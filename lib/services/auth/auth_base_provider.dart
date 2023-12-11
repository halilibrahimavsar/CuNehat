import 'package:cunehat/services/auth/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthProvidr {
  Future<UserCredential> googleSignIn();
  Future<void> initialize();
  AuthUser? get currentUser;

  Future<AuthUser> logIn({
    required String email,
    required String password,
  });

  Future<AuthUser> createUser({
    required String email,
    required String password,
  });

  Future<void> logOut();
  Future<void> sendEmailVerification();
  Future<void> sendPasswordReset({required String toEmail});
  void keepSignIn();
}
