import 'dart:async';

import 'package:cunehat/core/utils/error_handler.dart';
import 'package:cunehat/features/auth_feature/domain/entities/user_entity.dart';
import 'package:cunehat/features/auth_feature/domain/repository/auth_repository.dart';
import 'package:cunehat/features/auth_feature/domain/usecases/local_auth_usecases/manage_local_auth_usecase.dart';
import 'package:cunehat/features/auth_feature/domain/usecases/remote_auth_usecases/sign_in_with_google.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'remote_auth_event.dart';
part 'remote_auth_state.dart';

class RemoteAuthBloc extends Bloc<RemoteAuthEvent, AuthState>
    with WidgetsBindingObserver {
  final SignInWithGoogle _signInWithGoogle;
  final AuthRepository _authRepository;
  final ManageLocalAuthUseCase _manageLocalAuthUseCase;
  StreamSubscription<UserEntity?>? _userSubscription;
  DateTime? _lastUnlockTime;

  RemoteAuthBloc({
    required SignInWithGoogle signInWithGoogle,
    required AuthRepository authRepository,
    required ManageLocalAuthUseCase manageLocalAuthUseCase,
  })  : _signInWithGoogle = signInWithGoogle,
        _authRepository = authRepository,
        _manageLocalAuthUseCase = manageLocalAuthUseCase,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithGoogleRequested>(_onSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<AuthUnlockRequested>(_onAuthUnlockRequested);
    on<AuthAppResumed>(_onAuthAppResumed);

    // App başlatıldığında auth state kontrolü
    add(AuthCheckRequested());

    // Lifecycle dinleyicisini kaydet
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      add(AuthAppResumed());
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Mevcut abonelik varsa iptal et
    await _userSubscription?.cancel();
    // Repository'deki stream'i dinle
    _userSubscription = _authRepository.userChanges.listen((user) {
      add(AuthStateChanged(user));
    });
  }

  Future<void> _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user != null) {
      // Kullanıcı giriş yapmış, şimdi yerel güvenlik kontrolü yapalım
      final isBioEnabled = await _manageLocalAuthUseCase.isBiometricEnabled();
      final isPinSet = await _manageLocalAuthUseCase.isPinCodeSet();

      if (isBioEnabled || isPinSet) {
        emit(AuthLocked(event.user!));
      } else {
        emit(Authenticated(event.user!));
      }
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onAuthUnlockRequested(
    AuthUnlockRequested event,
    Emitter<AuthState> emit,
  ) async {
    _lastUnlockTime = DateTime.now();
    // Kilit ekranı başarıyla geçildi, normal authenticated durumuna dön
    emit(Authenticated(event.user));
  }

  Future<void> _onAuthAppResumed(
    AuthAppResumed event,
    Emitter<AuthState> emit,
  ) async {
    // Sadece zaten giriş yapmış (Authenticated) kullanıcılar için kontrol et
    if (state is Authenticated) {
      // Eğer son 2 saniye içinde kilit açıldıysa, bu resume işlemi biyometrik pencereden dönüş olabilir.
      if (_lastUnlockTime != null &&
          DateTime.now().difference(_lastUnlockTime!).inSeconds < 2) {
        return;
      }

      final currentUser = (state as Authenticated).user;
      final isBioEnabled = await _manageLocalAuthUseCase.isBiometricEnabled();
      final isPinSet = await _manageLocalAuthUseCase.isPinCodeSet();

      if (isBioEnabled || isPinSet) {
        emit(AuthLocked(currentUser));
      }
    }
  }

  Future<void> _onSignInRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _signInWithGoogle();
      // Başarılı olursa stream tetiklenecek ve AuthStateChanged çalışacak
    } catch (e) {
      emit(AuthError(ErrorHandler.handleException(e).message));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      // Başarılı olursa stream tetiklenecek ve AuthStateChanged çalışacak
    } catch (e) {
      emit(AuthError(ErrorHandler.handleException(e).message));
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _userSubscription?.cancel();
    return super.close();
  }
}
