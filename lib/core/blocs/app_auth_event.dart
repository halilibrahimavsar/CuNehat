import 'package:remote_auth_module/remote_auth_module.dart';

/// App-level auth events for lock/unlock functionality.
abstract class AppAuthEvent {
  const AppAuthEvent();
}

/// User successfully unlocked (PIN/biometric).
class AppAuthUnlockRequested extends AppAuthEvent {
  final AuthUser user;
  const AppAuthUnlockRequested(this.user);
}

/// App resumed from background — check if lock is needed.
class AppAuthAppResumed extends AppAuthEvent {
  const AppAuthAppResumed();
}

/// Forward a sign-in event to the inner AuthBloc.
class AppSignInWithGoogleRequested extends AppAuthEvent {
  const AppSignInWithGoogleRequested();
}

/// Forward a sign-out event to the inner AuthBloc.
class AppSignOutRequested extends AppAuthEvent {
  const AppSignOutRequested();
}
