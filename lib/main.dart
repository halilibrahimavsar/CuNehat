import 'package:cunehat/config/routes/gorouting.dart';
import 'package:cunehat/config/theme/bloc/theme_bloc.dart';
import 'package:cunehat/config/theme/custome_theme.dart';
import 'package:cunehat/firestore/firestore_bloc/firestore_bloc.dart';
import 'package:cunehat/firestore/firestore_service.dart';
import 'package:firebase_bloc_auth/call_firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

ThemeData selectedThemeName = CustomeAppThemes.glassTheme;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await Firebase.initializeApp();

  // TODO: After finish debugging, you can uncomment this
  // runApp(const CallFirebaseAuth(privateWidget: CuNehatEngine()));
  runApp(const CuNehatEngine());
}

class CuNehatEngine extends StatelessWidget {
  const CuNehatEngine({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => FirestoreService(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => FirestoreBloc(
              firestoreService:
                  RepositoryProvider.of<FirestoreService>(context),
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
              themeMode: ThemeMode
                  .light, // we do that becase "ThemeMode.system" can crush our theme mode selector BLoC
              theme: selectedThemeName,
              title: "CuNehat",
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    );
  }
}
