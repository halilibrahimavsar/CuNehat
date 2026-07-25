import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:cunehat/config/initialization/app_initialization.dart';
import 'package:cunehat/config/app/app_providers.dart';
import 'package:cunehat/core/pages/init_error_page.dart';
import 'package:cunehat/core/widgets/cunehat_app.dart';
import 'package:cunehat/config/app/themed_app.dart';

/// Application entry point.
///
/// Initializes the app and sets up dependency injection.
Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  try {
    runApp(await _buildApp());
  } catch (e, st) {
    // Init (Hive/DI) fırlatırsa runApp hiç çağrılmaz ve kullanıcı native
    // splash'ta sonsuza dek kalırdı; bunun yerine tekrar denenebilir bir
    // hata ekranı göster. AppInitialization.initialize idempotenttir.
    debugPrint('Açılış başarısız: $e\n$st');
    runApp(InitErrorApp(error: '$e', buildApp: _buildApp));
  } finally {
    FlutterNativeSplash.remove();
  }
}

Future<Widget> _buildApp() async {
  final result = await AppInitialization.initialize();
  return AppProviders(
    authBloc: result.authBloc,
    router: result.router,
    child: ThemedApp(
      builder: (theme, locale) => CuNehatApp(
        router: result.router,
        theme: theme,
        locale: locale,
      ),
    ),
  );
}
