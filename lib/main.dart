import 'package:cunehat/core/config/routes/gorouting.dart';
import 'package:cunehat/core/config/theme/bloc/theme_bloc.dart';
import 'package:cunehat/features/wallet/domain/model/wallet_model.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/models/expense_model.dart';
import 'package:cunehat/models/income_model.dart';
import 'package:cunehat/models/investment_model.dart';
import 'package:firebase_bloc_auth/call_firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// **Main Entry Point**
///
/// ✅ FIXED: WalletBloc now provided at app level for proper state sharing
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('tr_TR');
  await Firebase.initializeApp();
  await Hive.initFlutter();

  // Register type adapters
  Hive.registerAdapter(IncomeModelAdapter());
  Hive.registerAdapter(ExpenseModelAdapter());
  Hive.registerAdapter(WalletModelAdapter());
  Hive.registerAdapter(InvestmentModelAdapter());
  // await Hive.openBox<IncomeModel>('incomes');
  // await Hive.openBox<ExpenseModel>('expenses');
  // await Hive.openBox<WalletModel>('wallets');
  await Hive.openBox<InvestmentModel>('investments');

  debugPrint('✅ Hive TypeAdapters registered');

  // Initialize services
  // final localDataService = LocalDataService();
  // await localDataService.init();
  // debugPrint('✅ Local storage initialized');

  // final sharedPreferences = await SharedPreferences.getInstance();
  // final firestoreService = FirestoreService();

  // final syncService = SyncService(firestoreService: firestoreService);
  // await syncService.init();
  // debugPrint('✅ Sync service initialized');

  // syncService.startAutoSync();
  // debugPrint('✅ Auto-sync enabled');

  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => ThemeBloc(),
      ),
      BlocProvider(
        create: (context) => WalletBloc(),
      ),
    ],
    child: const CallFirebaseAuth(privateWidget: CuNehatEngine()),
  ));
}

/// **Main App Widget**
///
/// ✅ FIXED: WalletBloc provided at app level, shared across all pages
class CuNehatEngine extends StatelessWidget {
  const CuNehatEngine({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return MaterialApp.router(
          routerConfig: appRouter,
          themeMode: ThemeMode.light,
          theme: state.name,
          title: "CuNehat",
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
