import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remote_auth_module/remote_auth_module.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:http/http.dart' as http;

import 'package:cunehat/core/blocs/app_auth_bloc.dart';

@module
abstract class AppModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @lazySingleton
  AmountVisibilityCubit get amountVisibilityCubit => AmountVisibilityCubit();

  @lazySingleton
  ConnectionCubit get connectionCubit => ConnectionCubit();

  // Local Auth Repository
  @lazySingleton
  LocalAuthRepository localAuthRepository(SharedPreferences prefs) {
    return SecureLocalAuthRepository(prefs: prefs);
  }

  // Local Auth Login Bloc
  @injectable
  LocalAuthLoginBloc localAuthLoginBloc(LocalAuthRepository repository) {
    return LocalAuthLoginBloc(repository: repository);
  }

  // Local Auth Settings Bloc
  @injectable
  LocalAuthSettingsBloc localAuthSettingsBloc(LocalAuthRepository repository) {
    return LocalAuthSettingsBloc(repository: repository);
  }

  // Remote Auth Repository from remote_auth_module
  @lazySingleton
  AuthRepository authRepository(
    FirebaseAuth firebaseAuth,
    FirebaseFirestore firestore,
  ) {
    return FirebaseAuthRepository(
      auth: firebaseAuth,
      firestore: firestore,
      createUserCollection: true,
    );
  }

  // AuthBloc from remote_auth_module
  @lazySingleton
  AuthBloc authBloc(AuthRepository repository) {
    return AuthBloc(repository: repository);
  }

  // AppAuthBloc (bridge BLoC for lock-screen support)
  @lazySingleton
  AppAuthBloc appAuthBloc(
    AuthBloc authBloc,
    LocalAuthRepository localAuthRepository,
  ) {
    return AppAuthBloc(
      authBloc: authBloc,
      localAuthRepository: localAuthRepository,
    );
  }

  @lazySingleton
  http.Client get httpClient => http.Client();
}
