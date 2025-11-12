import 'package:cunehat/config/routes/gorouting.dart';
import 'package:cunehat/config/theme/bloc/theme_bloc.dart';
import 'package:cunehat/config/theme/custome_theme.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_bloc.dart';
import 'package:cunehat/data_layer/firestore/firestore_service.dart';

import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart'; // Hive Adapter için
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart'; // Hive Adapter için
import 'package:cunehat/data_layer/data_repository.dart';
import 'package:cunehat/data_layer/local_storage/local_data_service.dart';
import 'package:firebase_bloc_auth/call_firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ThemeData selectedThemeName = CustomeAppThemes.glassTheme;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await Firebase.initializeApp();

  // --- HIVE ve Servis Başlatma ---
  // 1. Hive'ı başlat
  // Mobil uygulamalarda Hive'ın nerede saklanacağını belirtmemiz gerekir.
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // 2. Hive Adapter'lerini (TypeAdapter) kaydet
  // Model dosyalarına '.g.dart' eklediğimizde oluşan sınıflar.
  Hive.registerAdapter(IncomeAdapter());
  Hive.registerAdapter(ExpenseAdapter());

  // 3. Yerel servisleri ve SharedPreferences'i hazırla
  final localDataService = LocalDataService();
  await localDataService.init(); // Hive kutularını açar

  final sharedPreferences = await SharedPreferences.getInstance();
  // Firestore servisi zaten hazır (içinde başlatma metodu yok)
  final firestoreService = FirestoreService();
  // --- Başlatma Sonu ---

  runApp(
    // Bu servisleri tüm uygulamaya sağlamak için RepositoryProvider kullanıyoruz.
    // (veya MultiRepositoryProvider)
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
        // Ana Depo (DataRepository), diğer servisleri kullanarak oluşturulur
        RepositoryProvider<DataRepository>(
          create: (context) => DataRepository(
            localDataService: context.read<LocalDataService>(),
            firestoreService: context.read<FirestoreService>(),
            sharedPreferences: context.read<SharedPreferences>(),
          ),
        ),
      ],
      // CuNehatEngine() widget'ını buraya taşı
      child: CallFirebaseAuth(privateWidget: CuNehatEngine()),
    ),
  );
}

class CuNehatEngine extends StatelessWidget {
  const CuNehatEngine({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiRepositoryProvider 'main' fonksiyonuna taşındığı için
    // burada sadece BLoC provider'lar kaldı.
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DataBloc(
            // BLoC'a doğrudan DataRepository'yi veriyoruz
            dataRepository: RepositoryProvider.of<DataRepository>(context),
          ),
        ),
        BlocProvider(
          create: (context) => ThemeBloc(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          if (context.read<ThemeBloc>().state.name == "Dark") {
            selectedThemeName = CustomeAppThemes.glassTheme;
          } else {
            selectedThemeName = CustomeAppThemes.neoTheme;
          }

          return MaterialApp.router(
            routerConfig: appRouter,
            themeMode: ThemeMode.light,
            theme: selectedThemeName,
            title: "CuNehat",
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
