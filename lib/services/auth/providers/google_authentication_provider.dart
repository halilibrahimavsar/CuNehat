import 'package:cunehat/firebase_options.dart';
import 'package:cunehat/services/auth/auth_provider.dart';
import 'package:cunehat/services/auth/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthenticationProvider implements AuthProvider {
  static final GoogleSignIn googleSign = GoogleSignIn();

  @override
  googleSignIn() async {
    await initialize();
    final GoogleSignInAccount? googleUser = await googleSign.signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
    final gUserCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(gUserCredential);
  }

  @override
  Future<AuthUser> createUser(
      {required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  AuthUser? get currentUser => throw UnimplementedError;

  gUser() {
    print("___cur user_______");
    print(FirebaseAuth.instance.currentUser);
    return FirebaseAuth.instance.currentUser;
  }

  @override
  Future<void> initialize() async {
    /// Initialize default option from exported flutter configuration file
    /// this method shuld be called in main.dart file
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }

  @override
  void keepSignIn() {}

  @override
  Future<AuthUser> logIn({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logOut() async {
    googleSign.signOut();
    print("the user is isSignedIn ::::: ${await googleSign.isSignedIn()}");
  }

  @override
  Future<void> sendEmailVerification() {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordReset({required String toEmail}) {
    throw UnimplementedError();
  }

  Future<bool> googleSignInUser() async {
    return await googleSign.isSignedIn();
  }
}
