import 'package:cunehat/config/routes/gorouting.dart';
import 'package:cunehat/config/theme/bloc/theme_bloc.dart';
import 'package:cunehat/repository/models/pending_operation_model.dart';
import 'package:cunehat/repository/data_bloc/data_bloc.dart';
import 'package:cunehat/repository/repo_services/firestore/firestore_service.dart';
import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/data_repository.dart';
import 'package:cunehat/repository/repo_services/local/local_data_service.dart';
import 'package:cunehat/repository/repo_services/sync_service.dart';
import 'package:firebase_bloc_auth/call_firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **Main Entry Point**
///
/// Initialization Order:
/// 1. Flutter bindings
/// 2. Firebase
/// 3. Hive + TypeAdapters
/// 4. Migration check
/// 5. Services initialization
/// 6. App launch
void main() async {
  // Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Turkish locale
  await initializeDateFormatting('tr_TR');

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive
  await Hive.initFlutter();

  // ============ REGISTER TYPE ADAPTERS ============
  // ⚠️ Order matters: Register before opening boxes

  Hive.registerAdapter(IncomeAdapter()); // typeId: 0
  Hive.registerAdapter(ExpenseAdapter()); // typeId: 1
  Hive.registerAdapter(PendingOperationAdapter()); // typeId: 2

  debugPrint('✅ Hive TypeAdapters registered');

  // ============ CHECK FOR MIGRATION ============
  // Uncomment if you need to clear old data due to schema changes
  /*
  final prefs = await SharedPreferences.getInstance();
  final needsMigration = !(prefs.getBool('migration_v1_done') ?? false);
  
  if (needsMigration) {
    debugPrint('🔄 Running one-time migration...');
    
    try {
      // Delete old boxes
      await Hive.deleteBoxFromDisk('expenses_box');
      await Hive.deleteBoxFromDisk('incomes_box');
      await Hive.deleteBoxFromDisk('pending_operations_box');
      
      // Mark as done
      await prefs.setBool('migration_v1_done', true);
      debugPrint('✅ Migration completed');
    } catch (e) {
      debugPrint('⚠️  Migration error (continuing anyway): $e');
    }
  }
  */

  // ============ INITIALIZE SERVICES ============

  final localDataService = LocalDataService();
  await localDataService.init();
  debugPrint('✅ Local storage initialized');

  final sharedPreferences = await SharedPreferences.getInstance();
  final firestoreService = FirestoreService();

  // Initialize sync service
  final syncService = SyncService(firestoreService: firestoreService);
  await syncService.init();
  debugPrint('✅ Sync service initialized');

  // Start auto-sync when connection is available
  syncService.startAutoSync();
  debugPrint('✅ Auto-sync enabled');

  // ============ LAUNCH APP ============

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
        RepositoryProvider<SyncService>(
          create: (context) => syncService,
        ),
        RepositoryProvider<DataRepository>(
          create: (context) => DataRepository(
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
/// Provides:
/// - DataBloc for state management
/// - ThemeBloc for theme switching
/// - Router configuration
class CuNehatEngine extends StatelessWidget {
  const CuNehatEngine({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DataBloc(
            dataRepository: RepositoryProvider.of<DataRepository>(context),
          ),
        ),
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
