import 'dart:async';

import 'package:cunehat/features/auth_feature/data/datasources/biometric_data_source.dart';
import 'package:cunehat/features/auth_feature/domain/entities/user_entity.dart';
import 'package:cunehat/features/auth_feature/domain/repository/auth_repository.dart';
import 'package:cunehat/features/auth_feature/domain/usecases/sign_in_with_google.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> with WidgetsBindingObserver {
  final SignInWithGoogle _signInWithGoogle;
  final AuthRepository _authRepository;
  StreamSubscription<UserEntity?>? _userSubscription;

  AuthBloc({
    required SignInWithGoogle signInWithGoogle,
    required AuthRepository authRepository,
  })  : _signInWithGoogle = signInWithGoogle,
        _authRepository = authRepository,
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
      // Kullanıcı var, peki yerel güvenlik (PIN/Bio) açık mı?
      final bioService = BiometricService();
      final isBioEnabled = await bioService.isBiometricEnabled();
      final isPinSet = await bioService.isPinCodeSet();

      // Eğer PIN veya Biyometrik açıksa "Locked" durumuna geç, değilse direkt içeri al
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
    // Kilit ekranı başarıyla geçildi, normal authenticated durumuna dön
    emit(Authenticated(event.user));
  }

  Future<void> _onAuthAppResumed(
    AuthAppResumed event,
    Emitter<AuthState> emit,
  ) async {
    // Sadece zaten giriş yapmış (Authenticated) kullanıcılar için kontrol et
    if (state is Authenticated) {
      final currentUser = (state as Authenticated).user;
      final bioService = BiometricService();
      final isBioEnabled = await bioService.isBiometricEnabled();
      final isPinSet = await bioService.isPinCodeSet();

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
      emit(AuthError(e.toString()));
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
      emit(AuthError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _userSubscription?.cancel();
    return super.close();
  }
}
