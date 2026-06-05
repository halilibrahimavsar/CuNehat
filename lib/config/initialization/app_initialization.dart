import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/routes/gorouting.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/data/models/investment_type_adapter.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_type_adapter.dart';
import 'package:cunehat/features/investments/presentation/widgets/color_adapter.dart';
import 'package:cunehat/features/settings/presentation/blocs/theme_blocs/theme_bloc.dart';

class AppInitialization {
  static Future<AppInitializationResult> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // Bağımsız servis başlatma adımlarını paralel olarak yürütüyoruz.
      await Future.wait([
        _initializeHive(),
        _initializeDateFormatting(),
        ThemeBloc.preloadTheme(),
      ]);

      // Diğer tüm servisler ve modüller hazır olduktan sonra bağımlılık enjeksiyonunu yapılandırıyoruz.
      await configureDependencies();

      final authBloc = getIt<AppAuthBloc>();
      final router = createAppRouter(authBloc);

      return AppInitializationResult(
        authBloc: authBloc,
        router: router,
      );
    } catch (e) {
      debugPrint('Initialization error: $e');
      rethrow;
    }
  }

  static Future<void> _initializeHive() async {
    await Hive.initFlutter();
    _registerTypeAdapters();

    // Açılışta oluşabilecek race condition ve deadlock'ları önlemek için
    // Hive kutularını en baştan açıyoruz.
    await Future.wait([
      Hive.openBox<WalletModel>('wallets'),
      Hive.openBox<Map>('users'),
      Hive.openBox<TransactionModel>('transactions'),
      Hive.openBox<InvestmentModel>('investments_box'),
      Hive.openBox<DebtModel>('debts'),
      Hive.openBox<ReceivableModel>('receivables'),
    ]);
  }

  static Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('tr_TR');
  }

  static void _registerTypeAdapters() {
    Hive.registerAdapter(WalletModelAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(TransactionTypeModelAdapter());
    Hive.registerAdapter(InvestmentModelAdapter());
    Hive.registerAdapter(InvestmentTypeAdapter());
    Hive.registerAdapter(DebtModelAdapter());
    Hive.registerAdapter(ReceivableModelAdapter());
    Hive.registerAdapter(PaymentModelAdapter());
    Hive.registerAdapter(DebtTypeAdapter());
    Hive.registerAdapter(ColorAdapter());
  }
}

class AppInitializationResult {
  final AppAuthBloc authBloc;
  final GoRouter router;

  const AppInitializationResult({
    required this.authBloc,
    required this.router,
  });
}
