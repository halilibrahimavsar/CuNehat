import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/notification_settings_service.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/services/budget_alert_service.dart';
import 'package:cunehat/features/budgets/domain/usecases/get_budgets_usecase.dart';

/// App-ömürlü bütçe uyarı monitörü. İşlem defteri her değiştiğinde (hangi sayfa
/// açık olursa olsun) etkilenen cüzdanın bütçelerini GERÇEK harcamayla yeniden
/// hesaplar ve yeni geçilen eşikler (%80 uyarı / %100 aşım) için bildirim atar.
///
/// Neden bloc değil: BudgetsBloc sayfa-kapsamlıdır (yalnız Budgets sayfası
/// açıkken yaşar), bu yüzden başka sayfadan eklenen işlemde uyarı çıkmazdı.
/// Uyarı sorumluluğu app-ömürlü bu singleton'a taşındı; başlangıçta eager-init
/// edilir (app_initialization.dart).
///
/// finance.domain → budgets bağımlılığı YOK: tetik [TransactionsChangedNotifier]
/// (core) üzerinden gelir, böylece finance ↔ budgets döngüsü kapalı kalır.
@lazySingleton
class BudgetAlertMonitor {
  final GetBudgetsUsecase _getBudgets;
  final NotificationService _notifications;
  final NotificationSettingsService _notificationSettings;

  static const _alertService = BudgetAlertService();

  StreamSubscription<TransactionsChange>? _subscription;

  /// Cüzdan-başına son bilinen bütçe durumu; eşik geçişi bununla karşılaştırılır.
  final Map<String, List<BudgetEntity>> _previousByWallet = {};

  BudgetAlertMonitor(
    this._getBudgets,
    this._notifications,
    this._notificationSettings,
    TransactionsChangedNotifier notifier,
  ) {
    _subscription = notifier.stream.listen(_onTransactionsChanged);
  }

  Future<void> _onTransactionsChanged(TransactionsChange change) async {
    final userId = change.userId;
    final walletId = change.walletId;
    // Cüzdan bağlamı yoksa (ör. toplu CSV import) per-bütçe uyarısı atlanır.
    if (userId == null || walletId == null) return;

    final result = await _getBudgets(userId, walletId);
    result.fold((_) {}, (budgets) {
      final previous = _previousByWallet[walletId] ?? const <BudgetEntity>[];
      for (final alert in _alertService.detectCrossings(
        previous: previous,
        current: budgets,
      )) {
        if (_notificationSettings.isBudgetAlertsEnabled) {
          final exceeded = alert.level == BudgetAlertLevel.exceeded;
          _notifications.showNotification(
            id: alert.categoryId.hashCode,
            title: exceeded ? 'Bütçe Aşıldı!' : 'Bütçe Uyarısı',
            body: exceeded
                ? 'Dikkat: Bütçenizi aştınız!'
                : 'Dikkat: Bütçenizin %80\'ine ulaştınız.',
          );
        }
      }
      _previousByWallet[walletId] = budgets;
    });
  }

  @disposeMethod
  void dispose() => _subscription?.cancel();
}
