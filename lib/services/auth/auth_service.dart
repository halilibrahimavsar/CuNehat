import 'package:cunehat/services/auth/auth_provider.dart';
import 'package:cunehat/services/auth/auth_user.dart';
import 'package:cunehat/services/auth/providers/firebase_auth_provider.dart';

class AuthService implements AuthProvider {
  final AuthProvider provider;

  const AuthService(this.provider);

  // Using the factory constructor here is for take the options from initialized FirebaseAuthProvider.
  // So instead of creating copy of the class, we takes already created one.
  // This is how factory constructor works
  factory AuthService.firebase() =>
      AuthService(FirebaseAuthProvider()); // this one is for email-pasword auth
  // By the way, this class works as Polymorphism. So this mean,
  // when you want to change or create new provider same as google, facebook, etc...
  // then simply you can add it to the factory constructure and you are good to go

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
  void keepSignIn() {
    provider.keepSignIn();
  }
}
