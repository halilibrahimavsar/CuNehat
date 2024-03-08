import 'dart:developer';

import 'package:cunehat/firebase_options.dart';
import 'package:cunehat/services/auth/auth_base_provider/auth_base_provider.dart';
import 'package:cunehat/services/auth/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthenticationProvider implements AuthProvidr {
  static final GoogleSignIn googleSign = GoogleSignIn();

  @override
  Future<UserCredential> googleSignIn() async {
    final GoogleSignInAccount? googleUser = await googleSign.signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
    final gUserCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    try {
      return await FirebaseAuth.instance.signInWithCredential(gUserCredential);
    } on FirebaseAuthException catch (e) {
      log(e.toString());
      await FirebaseAuth.instance.signOut();
      const Duration(milliseconds: 10);
      return await FirebaseAuth.instance.signInWithCredential(gUserCredential);
    }
  }

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  AuthUser? get currentUser {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return AuthUser.fromFirebase(user);
    } else {
      return null;
    }
  }

  @override
  Future<void> initialize() async {
    /// Initialize default option from exported flutter configuration file
    /// this method shuld be called in main.dart file
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Stream<User?> isUserKeepSigned() {
    return FirebaseAuth.instance.authStateChanges();
  }

  @override
  Future<AuthUser> logIn({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logOut() async {
    googleSign.signOut();
  }

  @override
  Future<void> sendEmailVerification() {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordReset({required String toEmail}) {
    throw UnimplementedError();
  }

  Future<bool> isGoogleUserSignedIn() async {
    return await googleSign.isSignedIn();
  }
}
