import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

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
    return SharedPrefsLocalAuthRepository(prefs: prefs);
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
}
