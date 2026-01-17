import 'package:flutter/material.dart';
import 'package:cunehat/config/initialization/app_initialization.dart';
import 'package:cunehat/config/di/global_providers.dart';
import 'package:cunehat/config/di/app_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Uygulama başlatma işlemleri
    await AppInitialization.initialize();
    runApp(const GlobalProviders(child: AppInjection()));
  } catch (e, stack) {
    // Kritik başlatma hatası durumunda (Loglama yapılabilir)
    debugPrint('Uygulama başlatılamadı: $e\n$stack');
    // İstenirse burada basit bir ErrorWidget ile runApp çağrılabilir.
  }
}
