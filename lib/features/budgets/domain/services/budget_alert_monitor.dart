import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cunehat/core/notifications/notification_constants.dart';
import 'package:cunehat/core/notifications/notification_localizer.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/notification_settings_service.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/services/budget_alert_service.dart';
import 'package:cunehat/features/budgets/domain/usecases/get_budgets_usecase.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';

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
  final NotificationLocalizer _localizer;
  final SharedPreferences _prefs;

  static const _alertService = BudgetAlertService();

  /// Eşik karşılaştırmasının dayandığı önceki durum, kalıcı saklanır.
  static const String _baselineKey = 'budget_alert_baseline';

  StreamSubscription<TransactionsChange>? _subscription;

  /// Cüzdan-başına son bilinen bütçe durumu; eşik geçişi bununla karşılaştırılır.
  ///
  /// Yalnız bellekte tutulduğunda her açılışta sıfırlanıyor ve "önceki oran 0"
  /// kabul edildiği için zaten eşiğin üstünde olan bütçeler her oturumun ilk
  /// işleminde yeniden uyarı üretiyordu. Bu yüzden diske de yazılır.
  final CategoryRepository _categories;

  final Map<String, List<BudgetEntity>> _previousByWallet = {};

  BudgetAlertMonitor(
    this._getBudgets,
    this._notifications,
    this._notificationSettings,
    this._localizer,
    this._prefs,
    this._categories,
    TransactionsChangedNotifier notifier,
  ) {
    _loadBaseline();
    _subscription = notifier.stream.listen(_onTransactionsChanged);
  }

  Future<void> _onTransactionsChanged(TransactionsChange change) async {
    final userId = change.userId;
    final walletId = change.walletId;
    // Cüzdan bağlamı yoksa (ör. toplu CSV import) per-bütçe uyarısı atlanır.
    if (userId == null || walletId == null) return;

    final result = await _getBudgets(userId, walletId);
    final budgets = result.fold((_) => null, (value) => value);
    if (budgets == null) return;

    final previous = _previousByWallet[walletId] ?? const <BudgetEntity>[];
    final crossings = _alertService.detectCrossings(
      previous: previous,
      current: budgets,
    );

    // Uyarılar kapalıyken de temel durum ilerletilir: aksi halde anahtar
    // yeniden açıldığında geçmişte kalmış tüm eşikler toptan bildirilirdi.
    if (_notificationSettings.isBudgetAlertsEnabled) {
      final l10n = _localizer.l10n;
      // Bildirim gövdesine eskiden HAM `categoryId` basılıyordu. Kimlik artık
      // UUID; ayrıca alt kategoride yalnız "Elektrik" demek bağlamı kaybeder,
      // "Fatura › Elektrik" gerekir.
      //
      // Çıplak stream dinleyicisindeyiz: buradan kaçan bir hata aboneliği
      // öldürür ve bütçe uyarıları oturum boyunca susar. Ad çözülemezse
      // bildirim kimlikle gider ama akış sürer.
      var breadcrumbs = const <String, String>{};
      try {
        breadcrumbs = buildBreadcrumbs(await _categories.getAllCategories());
      } catch (e) {
        debugPrint('BudgetAlertMonitor: kategori adları okunamadı: $e');
      }
      String nameOf(String id) => breadcrumbs[id] ?? id;
      for (final alert in crossings) {
        final String title;
        final String body;
        switch (alert.level) {
          case BudgetAlertLevel.exceeded:
            title = l10n.notifBudgetExceededTitle;
            body = l10n.notifBudgetExceededBody(nameOf(alert.categoryId));
          case BudgetAlertLevel.filled:
            title = l10n.notifBudgetFilledTitle;
            body = l10n.notifBudgetFilledBody(nameOf(alert.categoryId));
          case BudgetAlertLevel.warning:
            title = l10n.notifBudgetWarningTitle;
            body = l10n.notifBudgetWarningBody(nameOf(alert.categoryId));
        }
        await _notifications.showNotification(
          // Bütçeler cüzdan bazlı: yalnız categoryId kullanılırsa aynı
          // kategoriyi iki cüzdanda bütçeleyen kullanıcıda ikinci uyarı
          // birincinin üstüne yazar.
          id: ReminderIds.budget(walletId, alert.categoryId),
          title: title,
          body: body,
          payload: NotificationPayloads.budgetAlert,
        );
      }
    }

    _previousByWallet[walletId] = budgets;
    await _persistBaseline();
  }

  void _loadBaseline() {
    final raw = _prefs.getString(_baselineKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((walletId, byCategory) {
        _previousByWallet[walletId] =
            (byCategory as Map<String, dynamic>).entries.map((entry) {
          final pair = (entry.value as List).cast<num>();
          return BudgetEntity(
            categoryId: entry.key,
            walletId: walletId,
            limitAmount: pair[0].toDouble(),
            spentAmount: pair[1].toDouble(),
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('Budget alert baseline unreadable, resetting: $e');
      _previousByWallet.clear();
      _prefs.remove(_baselineKey);
    }
  }

  Future<void> _persistBaseline() async {
    final snapshot = <String, Map<String, List<double>>>{
      for (final entry in _previousByWallet.entries)
        entry.key: {
          for (final budget in entry.value)
            budget.categoryId: [budget.limitAmount, budget.spentAmount],
        },
    };
    await _prefs.setString(_baselineKey, jsonEncode(snapshot));
  }

  @disposeMethod
  void dispose() => _subscription?.cancel();
}
