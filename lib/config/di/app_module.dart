import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:cunehat/core/blocs/app_auth_bloc.dart';

@module
abstract class AppModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @lazySingleton
  AmountVisibilityCubit get amountVisibilityCubit => AmountVisibilityCubit();

  // Local Auth Repository
  @lazySingleton
  LocalAuthRepository localAuthRepository(SharedPreferences prefs) {
    return SecureLocalAuthRepository(prefs: prefs);
  }

  // Local Auth Login Bloc
  @injectable
  LocalAuthLoginBloc localAuthLoginBloc(LocalAuthRepository repository) {
    // Varsayılan İngilizce texts. Gerçek dil, UnifiedFeaturesTextsProvider
    // aracılığıyla widget ağacında inject edilir (bkz. context.localAuthTexts).
    return LocalAuthLoginBloc(repository: repository);
  }

  // Local Auth Settings Bloc
  @injectable
  LocalAuthSettingsBloc localAuthSettingsBloc(LocalAuthRepository repository) {
    // Varsayılan İngilizce texts. Gerçek dil, UnifiedFeaturesTextsProvider
    // aracılığıyla widget ağacında inject edilir (bkz. context.localAuthTexts).
    return LocalAuthSettingsBloc(repository: repository);
  }

  // AppAuthBloc (handles lock-screen and local session)
  @lazySingleton
  AppAuthBloc appAuthBloc(
    LocalAuthRepository localAuthRepository,
    SharedPreferences prefs,
  ) {
    return AppAuthBloc(
      localAuthRepository: localAuthRepository,
      sharedPreferences: prefs,
    );
  }

  @lazySingleton
  http.Client get httpClient => http.Client();

  @lazySingleton
  FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin =>
      FlutterLocalNotificationsPlugin();
}
