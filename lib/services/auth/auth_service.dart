import 'package:cunehat/services/auth/auth_base_provider/auth_base_provider.dart';
import 'package:cunehat/services/auth/auth_user.dart';
import 'package:cunehat/services/auth/providers/firebase_auth_provider.dart';
import 'package:cunehat/services/auth/providers/google_authentication_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService implements AuthProvidr {
  final AuthProvidr provider;

  const AuthService(this.provider);

  // Using the factory constructor here is for take the options from initialized FirebaseAuthProvider.
  // So instead of creating copy of the class, we takes already created one.
  // This is how factory constructor works
  factory AuthService.firebase() => AuthService(
        FirebaseEmailAuthProvider(),
      ); // this one is for email-pasword auth
  // By the way, this class works as Polymorphism. So this mean,
  // when you want to change or create new provider same as google, facebook, etc...
  // then simply you can add it to the factory constructure and you are good to go

  factory AuthService.google() => AuthService(GoogleAuthenticationProvider());

  @override
  Future<void> initialize() => provider.initialize();

  @override
  AuthUser? get currentUser => provider.currentUser;

  @override
  Future<AuthUser> createUser(
          {required String email, required String password}) =>
      provider.createUser(email: email, password: password);

  @override
  Future<AuthUser> logIn({required String email, required String password}) =>
      provider.logIn(email: email, password: password);

  @override
  Future<void> logOut() => provider.logOut();

  @override
  Future<void> sendEmailVerification() => provider.sendEmailVerification();

  @override
  Future<void> sendPasswordReset({required String toEmail}) =>
      provider.sendPasswordReset(toEmail: toEmail);

  @override
  Stream<User?> isUserKeepSigned() {
    return provider.isUserKeepSigned();
  }

  @override
  Future<UserCredential> googleSignIn() {
    return provider.googleSignIn();
  }
}
