import 'package:cunehat/config/routes/gorouting.dart';
import 'package:cunehat/config/theme/bloc/theme_bloc.dart';
import 'package:cunehat/repository/get_storage_mod.dart';
import 'package:cunehat/repository/data_bloc/data_bloc.dart';
import 'package:cunehat/repository/models/wallet_model.dart';
import 'package:cunehat/repository/repo_services/firestore/firestore_service.dart';
import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/data_repository.dart';
import 'package:cunehat/repository/repo_services/local/local_data_service.dart';
import 'package:cunehat/repository/repo_services/sync_service.dart';
import 'package:cunehat/repository/wallet_bloc/wallet_bloc.dart';
import 'package:firebase_bloc_auth/call_firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **Main Entry Point**
///
/// ✅ FIXED: WalletBloc now provided at app level for proper state sharing
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('tr_TR');
  await Firebase.initializeApp();
  await Hive.initFlutter();

  // Register type adapters
  Hive.registerAdapter(IncomeAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(WalletAdapter());

  debugPrint('✅ Hive TypeAdapters registered');

  // Initialize services
  final localDataService = LocalDataService();
  await localDataService.init();
  debugPrint('✅ Local storage initialized');

  final sharedPreferences = await SharedPreferences.getInstance();
  final firestoreService = FirestoreService();

  final syncService = SyncService(firestoreService: firestoreService);
  await syncService.init();
  debugPrint('✅ Sync service initialized');

  syncService.startAutoSync();
  debugPrint('✅ Auto-sync enabled');

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocalDataService>(
          create: (context) => localDataService,
        ),
        RepositoryProvider<FirestoreService>(
          create: (context) => firestoreService,
        ),
        RepositoryProvider<SharedPreferences>(
          create: (context) => sharedPreferences,
        ),
        RepositoryProvider<GetStorageMod>(
          create: (context) => GetStorageMod(
            prefs: context.read<SharedPreferences>(),
            firestoreService: context.read<FirestoreService>(),
            localDataService: context.read<LocalDataService>(),
          ),
        ),
        RepositoryProvider<SyncService>(
          create: (context) => syncService,
        ),
        RepositoryProvider<DataRepository>(
          create: (context) => DataRepository(
            getStorageMod: context.read<GetStorageMod>(),
            localDataService: context.read<LocalDataService>(),
            firestoreService: context.read<FirestoreService>(),
            sharedPreferences: context.read<SharedPreferences>(),
            syncService: context.read<SyncService>(),
          ),
        ),
      ],
      child: const CallFirebaseAuth(privateWidget: CuNehatEngine()),
    ),
  );
}

/// **Main App Widget**
///
/// ✅ FIXED: WalletBloc provided at app level, shared across all pages
class CuNehatEngine extends StatelessWidget {
  const CuNehatEngine({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ✅ CRITICAL FIX: WalletBloc at app level (shared state)
        BlocProvider(
          create: (context) => WalletBloc(
            repository: RepositoryProvider.of<DataRepository>(context),
          )..add(LoadWalletsEvent()),
        ),
        // DataBloc also at app level
        BlocProvider(
          create: (context) => DataBloc(
            dataRepository: RepositoryProvider.of<DataRepository>(context),
          ),
        ),
        // ThemeBloc at app level
        BlocProvider(
          create: (context) => ThemeBloc(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp.router(
            routerConfig: appRouter,
            themeMode: ThemeMode.light,
            theme: state.name,
            title: "CuNehat",
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
