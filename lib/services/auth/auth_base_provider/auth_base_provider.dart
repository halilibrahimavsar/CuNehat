import 'package:cunehat/services/auth/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthProvidr {
  // shared function
  Stream<User?> isUserKeepSigned();
  // email provider
  AuthUser? get currentUser;
  Future<void> initialize();

  Future<AuthUser> createUser({
    required String email,
    required String password,
  });

  Future<AuthUser> logIn({
    required String email,
    required String password,
  });

  Future<void> logOut();
  Future<void> sendEmailVerification();
  Future<void> sendPasswordReset({required String toEmail});
  // google provider
  Future<UserCredential> googleSignIn();
}
