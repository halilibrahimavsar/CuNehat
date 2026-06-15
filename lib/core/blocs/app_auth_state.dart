import 'package:cunehat/core/models/local_user.dart';
import 'package:equatable/equatable.dart';

/// App-level auth state that wraps local authentication and adds lock support.
abstract class AppAuthState extends Equatable {
  const AppAuthState();

  @override
  List<Object?> get props => [];
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

  @override
  List<Object?> get props => [user];
}

/// An error occurred during authentication.
class AppAuthError extends AppAuthState {
  final String message;
  const AppAuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// User is authenticated but app is locked (PIN/biometric required).
class AppAuthLocked extends AppAuthState {
  final LocalUser user;
  const AppAuthLocked(this.user);

  @override
  List<Object?> get props => [user];
}
