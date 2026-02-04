import 'package:injectable/injectable.dart';
import 'package:unified_flutter_features/features/amount_visibility/amount_visibility_cubit.dart';
import 'package:unified_flutter_features/features/connection_monitor/connection_cubit.dart';

@module
abstract class AppModule {
  // @lazySingleton
  // Connectivity get connectivity => Connectivity();

  @lazySingleton
  AmountVisibilityCubit get amountVisibilityCubit => AmountVisibilityCubit();

  @lazySingleton
  ConnectionCubit get connectionCubit => ConnectionCubit();
}
