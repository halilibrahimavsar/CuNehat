import 'package:cunehat/config/routes/gorouting.dart';
import 'package:cunehat/config/theme/bloc/theme_bloc.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/pending_operation_model.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_bloc.dart';
import 'package:cunehat/data_layer/firestore/firestore_service.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:cunehat/data_layer/data_repository.dart';
import 'package:cunehat/data_layer/local_storage/local_data_service.dart';
import 'package:cunehat/data_layer/sync_service.dart';
import 'package:firebase_bloc_auth/call_firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await Firebase.initializeApp();

  await Hive.initFlutter();

  // Adapter kayıtları
  Hive.registerAdapter(IncomeAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  // PendingOperation adapter'ını da kaydet (build_runner çalıştırdıktan sonra)
  Hive.registerAdapter(PendingOperationAdapter());

  // Servisleri hazırla
  final localDataService = LocalDataService();
  await localDataService.init();

  final sharedPreferences = await SharedPreferences.getInstance();
  final firestoreService = FirestoreService();

  // Sync servisini başlat
  final syncService = SyncService(firestoreService: firestoreService);
  await syncService.init();

  // Otomatik senkronizasyonu başlat
  syncService.startAutoSync();

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
      child: CallFirebaseAuth(privateWidget: const CuNehatEngine()),
    ),
  );
}

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
