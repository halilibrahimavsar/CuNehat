part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class SignInWithGoogleRequested extends AuthEvent {}

class SignOutRequested extends AuthEvent {}

class AuthStateChanged extends AuthEvent {
  final UserEntity? user;

  const AuthStateChanged(this.user);

  @override
  List<UserEntity?> get props => [user];
}

class AuthUnlockRequested extends AuthEvent {
  final UserEntity user;

  const AuthUnlockRequested(this.user);

  @override
  List<UserEntity> get props => [user];
}
