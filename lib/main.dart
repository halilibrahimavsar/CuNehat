import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/initialization/app_initialization.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/config/di/cunehat_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Uygulama başlatma işlemleri
    await AppInitialization.initialize();
    await configureDependencies();

    // runApp(const GlobalProviders(child: AppInjection()));
    runApp(CuNehatEngine());
  } catch (e, stack) {
    // Kritik başlatma hatası durumunda (Loglama yapılabilir)
    debugPrint('Uygulama başlatılamadı: $e\n$stack');
    // İstenirse burada basit bir ErrorWidget ile runApp çağrılabilir.
  }
}
