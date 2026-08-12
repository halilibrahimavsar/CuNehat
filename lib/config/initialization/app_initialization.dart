import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/routes/gorouting.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/services/auto_backup_service.dart';
import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/reminder_sync_service.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/category_local_datasource.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/data/models/investment_type_adapter.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_calc_mode_adapter.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_type_adapter.dart';
import 'package:cunehat/features/budgets/data/models/budget_model.dart';
import 'package:cunehat/features/budgets/domain/services/budget_alert_monitor.dart';
import 'package:cunehat/features/investments/presentation/widgets/color_adapter.dart';
import 'package:cunehat/features/settings/presentation/blocs/theme_blocs/theme_bloc.dart';
import 'package:cunehat/features/settings/presentation/blocs/language_bloc/language_bloc.dart';
import 'package:cunehat/features/recurring_transactions/data/models/recurring_transaction_model.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';

class AppInitialization {
  static Future<AppInitializationResult> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // Bağımsız servis başlatma adımlarını paralel olarak yürütüyoruz.
      await Future.wait([
        _initializeHive(),
        _initializeDateFormatting(),
        ThemeBloc.preloadTheme(),
        LanguageBloc.preloadLanguage(),
      ]);

      // Diğer tüm servisler ve modüller hazır olduktan sonra bağımlılık
      // enjeksiyonunu yapılandırıyoruz. Retry'da (init hata ekranı) ikinci
      // kez kayıt GetIt'te fırlatır; sentinel ile atla.
      if (!getIt.isRegistered<AppAuthBloc>()) {
        await configureDependencies();
      }

      // Ekranlardaki interaktif turlar (Showcase) için global kayıt. v5
      // API'si artık widget ağacında bir üst (ShowcaseWidget) gerektirmiyor;
      // herhangi bir yerdeki Showcase, ShowcaseView.get() ile bu kayda
      // bağlanır. onFinish/onDismiss, OnboardingCoordinator'ın kuyruğunu
      // (aynı anda birden çok ekranın kendi turunu tetiklemesi durumunda
      // sırayla oynatılmasını sağlayan mekanizma) serbest bırakır — bu
      // yüzden getIt hazır olduktan SONRA kayıt yapılır.
      ShowcaseView.register(
        onFinish: () => getIt<OnboardingCoordinator>().handleShowcaseIdle(),
        onDismiss: (_) => getIt<OnboardingCoordinator>().handleShowcaseIdle(),
        // Ekleme sheet'lerinin turları kaydırılabilir formda ilerliyor
        // (tutar → kategori → tekrar). SingleChildScrollView tembel
        // olmadığından hedefler "render edilmiş" sayılır ama ekranın altında
        // kalabilir; bu bayrak olmadan overlay görünmeyen bir yeri
        // işaretlerdi. Kaydırılabilir atası olmayan hedeflerde (appBar)
        // sessizce etkisizdir.
        enableAutoScroll: true,
      );

      // Bildirim servisi: soğuk açılışta dokunulan bildirimin yükünü de
      // burada okur ve ilk dinleyici bağlanana kadar tamponlar. Widget ağacı
      // kurulmadan ÖNCE çalışması bu yüzden önemli.
      await getIt<NotificationService>().initialize();

      // Planlanmış tüm hatırlatmaları güncel veriye/ayara/dile göre yeniden
      // kur. Fire-and-forget: onlarca platform-channel çağrısı yapıyor,
      // açılışı bloklamamalı.
      unawaited(getIt<ReminderSyncService>().syncAll());

      // Bütçe uyarı monitörünü erken canlandır: app-ömürlü olarak işlem
      // defteri değişimlerini dinler ve eşik aşımında bildirim atar (Budgets
      // sayfası açık olmasa da). lazySingleton olduğundan bir kez touch edilir.
      getIt<BudgetAlertMonitor>();

      // Otomatik Drive yedeği uygulama arka plana geçerken tetiklenir; dinleyici
      // servisin kurucusunda kaydolduğu için servis en az bir kez oluşturulmalı.
      // Ayar kapalıysa tur ilk kapıda döner, maliyeti yok.
      getIt<AutoBackupService>();

      // Kur ısıtması: tek çağrı USD+EUR'u önbelleğe alır; açılışı bloklamaz,
      // hata durumunda servis sessizce bayat önbelleğe/null'a düşer.
      unawaited(getIt<ExchangeRateService>().rateToTry('USD'));

      final authBloc = getIt<AppAuthBloc>();
      final router = createAppRouter(authBloc);

      return AppInitializationResult(
        authBloc: authBloc,
        router: router,
      );
    } catch (e) {
      debugPrint('Initialization error: $e');
      rethrow;
    }
  }

  static Future<void> _initializeHive() async {
    await Hive.initFlutter();
    _registerTypeAdapters();

    // Açılışta oluşabilecek race condition ve deadlock'ları önlemek için
    // Hive kutularını en baştan açıyoruz.
    await Future.wait([
      Hive.openBox<WalletModel>('wallets'),
      Hive.openBox<Map>('users'),
      Hive.openBox<TransactionModel>('transactions'),
      Hive.openBox<InvestmentModel>('investments_box'),
      Hive.openBox<DebtModel>('debts'),
      Hive.openBox<ReceivableModel>('receivables'),
      Hive.openBox<BudgetModel>('budgets_box'),
      Hive.openBox<RecurringTransactionModel>('recurring_transactions_box'),
      Hive.openBox<CategoryModel>(CategoryLocalDataSource.boxName),
    ]);
  }

  static Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('tr_TR');
  }

  static void _registerTypeAdapters() {
    // İkinci kayıt HiveError fırlatır; retry (init hata ekranı) güvenli
    // olsun diye kayıtlıysa atla.
    void register<T>(TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter(adapter);
      }
    }

    register(WalletModelAdapter());
    register(TransactionModelAdapter());
    register(TransactionTypeModelAdapter());
    register(InvestmentModelAdapter());
    register(InvestmentTypeAdapter());
    register(DebtModelAdapter());
    register(ReceivableModelAdapter());
    register(PaymentModelAdapter());
    register(DebtTypeAdapter());
    register(DebtCalcModeAdapter());
    register(BudgetModelAdapter());
    register(RecurringTransactionModelAdapter());
    register(RecurringFrequencyAdapter());
    register(CategoryModelAdapter());
    register(ColorAdapter());
  }
}

class AppInitializationResult {
  final AppAuthBloc authBloc;
  final GoRouter router;

  const AppInitializationResult({
    required this.authBloc,
    required this.router,
  });
}
