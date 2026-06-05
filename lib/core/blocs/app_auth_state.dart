import 'package:cunehat/core/models/local_user.dart';

/// App-level auth state that wraps local authentication and adds lock support.
abstract class AppAuthState {
  const AppAuthState();
}

/// Initial state before auth status is determined.
class AppAuthInitial extends AppAuthState {
  const AppAuthInitial();
}

/// Auth status is being checked.
class AppAuthLoading extends AppAuthState {
  const AppAuthLoading();
}

/// User is authenticated and app is unlocked.
class AppAuthenticated extends AppAuthState {
  final LocalUser user;
  const AppAuthenticated(this.user);
}

/// An error occurred during authentication.
class AppAuthError extends AppAuthState {
  final String message;
  const AppAuthError(this.message);
}

/// User is authenticated but app is locked (PIN/biometric required).
class AppAuthLocked extends AppAuthState {
  final LocalUser user;
  const AppAuthLocked(this.user);
}
