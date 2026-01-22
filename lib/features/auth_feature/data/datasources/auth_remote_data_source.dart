import 'package:cunehat/core/error/auth_exceptions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

@singleton
class AuthRemoteDataSource {
  /// Google Sign In v7+ için sessiz giriş (oturum yenileme) metodu
  Future<void> signInSilently() async {
    final GoogleSignIn googleSignn = GoogleSignIn.instance;
    try {
      // v7+ sürümü için başlatma zorunludur
      await googleSignn.initialize();
    } catch (e) {
      // Sessiz giriş başarısız olursa (örn: kullanıcı daha önce giriş yapmamışsa) yoksay
    }
  }

  Future<void> logOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut().catchError(
          (error, stackTrace) => throw GoogleLogoutException(),
        );
  }

  Future<UserCredential> googleLogin() async {
    UserCredential userCredent;
    // -----------Google stuff-------------
    // Get configurations
    final GoogleSignIn googleSignn = GoogleSignIn.instance;

    // v7+ sürümü için başlatma zorunludur
    await googleSignn.initialize();

    // sign in user
    // signIn() yerine authenticate() kullanılıyor
    final GoogleSignInAccount googleUsr =
        await googleSignn.authenticate().catchError((error) {
      throw UserDisabledAuthException();
    });

    // Obtain the auth details from user(if signed in successfully into google)
    final GoogleSignInAuthentication googlAuth = googleUsr.authentication;

    // Access Token artık authorizationClient üzerinden alınıyor
    final GoogleSignInClientAuthorization authorization =
        await googleUsr.authorizationClient.authorizeScopes(['email']);

    // Create credential for Firebase
    final gUserCredential = GoogleAuthProvider.credential(
      accessToken: authorization.accessToken,
      idToken: googlAuth.idToken,
    );

    // -----------Firebase stuff-------------
    // Once signed in, return the User
    userCredent = await FirebaseAuth.instance
        .signInWithCredential(gUserCredential)
        .catchError(
      (error, stackTrace) {
        if (error.code == 'invalid-credential') {
          throw InvalidCredentialException();
        } else if (error.code == 'user-disabled') {
          throw UserDisabledAuthException();
        } else if (error.code == 'user-not-found') {
          throw UserNotFoundAuthException();
        } else if (error.code == 'wrong-password') {
          throw WrongPasswordAuthException();
        } else if (error.code == 'invalid-verification-code') {
          throw InvalidVerificationCodeException();
        } else if (error.code == 'invalid-verification-id') {
          throw InvalidVerificationIdException();
        } else if (error.code == 'account-exists-with-different-credential') {
          throw AccExistWithDifferentCredentialException();
        } else if (error.code == 'operation-not-allowed') {
          throw OperationNotAllowedException();
        } else {
          throw GenericAuthException();
        }
      },
    );
    return userCredent;
  }

  Stream<User?> get userChanges {
    return FirebaseAuth.instance.authStateChanges();
  }
}
