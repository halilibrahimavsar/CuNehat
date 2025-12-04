import 'package:cunehat/core/config/routes/gorouting.dart';
import 'package:cunehat/core/config/theme/bloc/theme_bloc.dart';
import 'package:cunehat/features/settings/data/repository/settings_repository_impl.dart';
import 'package:cunehat/features/wallet/data/datasource/wallet_hive.dart';
import 'package:cunehat/features/wallet/data/repository/wallet_repository_impl.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('tr_TR');
  await Firebase.initializeApp();
  await Hive.initFlutter();

  // Register type adapters
  Hive.registerAdapter(IncomeModelAdapter()); // typeId: 0
  Hive.registerAdapter(ExpenseModelAdapter()); // typeId: 1
  Hive.registerAdapter(WalletModelAdapter()); // typeId: 3
  Hive.registerAdapter(InvestmentModelAdapter()); // typeId: 4

  debugPrint('✅ Hive TypeAdapters registered');

  runApp(
    MultiRepositoryProvider(
      providers: [
        // ✅ Settings Repository
        RepositoryProvider(
          create: (context) => SettingsRepositoryImpl(),
        ),
        // ✅ Wallet Repository
        RepositoryProvider(
          create: (context) => WalletRepositoryImpl(
            dataSource: WalletHiveDataSource(),
          ),
        ),
      ],
      child: CallFirebaseAuth(
        privateWidget: CuNehatEngine(),
      ),
    ),
  );
}

class CuNehatEngine extends StatelessWidget {
  const CuNehatEngine({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Theme BLoC
        BlocProvider(
          create: (context) => ThemeBloc(),
        ),
        // Wallet BLoC
        BlocProvider(
          create: (context) =>
              WalletBloc(context.read<WalletRepositoryImpl>().dataSource),
        ),
        // ⚠️ Settings BLoC burada oluşturulmaz, SettingsPage'de oluşturulur
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
