part of 'remote_auth_bloc.dart';

abstract class RemoteAuthEvent extends Equatable {
  const RemoteAuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends RemoteAuthEvent {}

class SignInWithGoogleRequested extends RemoteAuthEvent {}

class SignOutRequested extends RemoteAuthEvent {}

class AuthStateChanged extends RemoteAuthEvent {
  final UserEntity? user;

  const AuthStateChanged(this.user);

  @override
  List<UserEntity?> get props => [user];
}

class AuthUnlockRequested extends RemoteAuthEvent {
  final UserEntity user;

  const AuthUnlockRequested(this.user);

  @override
  List<UserEntity> get props => [user];
}

class AuthAppResumed extends RemoteAuthEvent {}
