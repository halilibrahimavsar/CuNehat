import 'package:cunehat/core/models/local_user.dart';

/// App-level auth events for lock/unlock functionality.
abstract class AppAuthEvent {
  const AppAuthEvent();
}

/// User successfully unlocked (PIN/biometric).
class AppAuthUnlockRequested extends AppAuthEvent {
  final LocalUser user;
  const AppAuthUnlockRequested(this.user);
}

/// App resumed from background — check if lock is needed.
class AppAuthAppResumed extends AppAuthEvent {
  const AppAuthAppResumed();
}

/// Request app lock manually.
class AppAuthLockRequested extends AppAuthEvent {
  const AppAuthLockRequested();
}

/// Check and initialize local auth state on startup.
class AppAuthInitializeRequested extends AppAuthEvent {
  const AppAuthInitializeRequested();
}
