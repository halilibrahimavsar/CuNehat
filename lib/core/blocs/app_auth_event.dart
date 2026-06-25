import 'package:cunehat/core/models/local_user.dart';
import 'package:equatable/equatable.dart';

/// App-level auth events for lock/unlock functionality.
abstract class AppAuthEvent extends Equatable {
  const AppAuthEvent();

  @override
  List<Object?> get props => [];
}

class AppAuthUnlockRequested extends AppAuthEvent {
  final LocalUser user;
  const AppAuthUnlockRequested(this.user);

  @override
  List<Object?> get props => [user];
}

class AppAuthAppResumed extends AppAuthEvent {
  const AppAuthAppResumed();
}

class AppAuthLockRequested extends AppAuthEvent {
  const AppAuthLockRequested();
}

class AppAuthInitializeRequested extends AppAuthEvent {
  const AppAuthInitializeRequested();
}
