import 'package:bloc/bloc.dart';

import 'package:cunehat/core/error/error_handling.dart';

/// Bloc/Cubit hatalarını [reportError] kanalına aktarır.
///
/// `onError` hem handler içinde fırlayan hatalarda hem de `addError` ile
/// bildirilen hatalarda çağrılır. Handler hatası ayrıca yeniden fırlatılıp kök
/// zone'a da düşer; aynı hata nesnesinin iki kez yazılmasını `ErrorLog`
/// kimlik karşılaştırmasıyla önler.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    reportError('Bloc ${bloc.runtimeType}', error, stackTrace);
  }
}
