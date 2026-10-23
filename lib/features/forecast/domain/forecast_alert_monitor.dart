import 'dart:async';
import 'dart:convert';

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/notifications/notification_constants.dart';
import 'package:cunehat/core/notifications/notification_localizer.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/core/services/notification_settings_service.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/features/finance_transactions/data/period_preferences_store.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/forecast/data/forecast_service.dart';
import 'package:cunehat/features/forecast/domain/forecast_alerts.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart'
    show AmountVisibilityCubit;

/// Uygulama ömürlü tahmin bildirimleri: erken uyarı ve haftalık özet.
///
/// **Neden app-ömürlü:** Gelecek sayfası yalnız açıkken yaşar; uyarı başka
/// bir sayfada girilen harcamanın ardından da gelmeli (BudgetAlertMonitor ile
/// aynı gerekçe). Tetikler: defter ve bütçe değişimi, uygulamaya dönüş ve
/// arka plana geçiş. Üst üste gelen tetikler tek hesaba indirgenir.
///
/// **Haftalık özet** tek atışlık planlanır (Pazartesi 09:00) ve HER turda
/// yeniden kurulur: içerik planlandığı anın tahminidir, bayatlamasın diye
/// uygulama her kullanıldığında tazelenir. Tekrarlı plan
/// (`matchDateTimeComponents`) tarihi yok sayar ve içeriği dondururdu — bkz.
/// [NotificationService.scheduleNotification]. Bir hafta sonrası için ikinci
/// bir "bir haftadır kayıt yok" yedeği kurulur; uygulama açıldıkça o da ileri
/// kayar, yani yalnız gerçekten bir hafta açılmazsa çalar — unutturmamanın
/// kendisi.
@lazySingleton
class ForecastAlertMonitor with WidgetsBindingObserver {
  final ForecastService _forecasts;
  final NotificationService _notifications;
  final NotificationSettingsService _settings;
  final NotificationLocalizer _localizer;
  final SharedPreferences _prefs;
  final WalletRepository _wallets;
  final AmountVisibilityCubit _visibility;
  final DateTime Function() _clock;

  /// Gönderilmiş uyarı anahtarları (aynı olay ikinci kez bildirilmez).
  static const String sentKey = 'forecast_warn_sent';

  /// Son uyarının günü (günde en fazla bir uyarı).
  static const String lastDayKey = 'forecast_warn_last_day';

  static const int _maxRemembered = 200;

  /// Tetikleri birleştirme süresi: bir içe aktarım onlarca değişim yayınlar.
  final Duration debounce;

  final _subs = <StreamSubscription<Object?>>[];
  Timer? _timer;
  bool _running = false;
  bool _again = false;

  ForecastAlertMonitor(
    this._forecasts,
    this._notifications,
    this._settings,
    this._localizer,
    this._prefs,
    this._wallets,
    this._visibility,
    TransactionsChangedNotifier transactions,
    BudgetsChangedNotifier budgets,
  )   : _clock = DateTime.now,
        debounce = const Duration(seconds: 2) {
    _subs.add(transactions.stream.listen((_) => schedule()));
    _subs.add(budgets.stream.listen((_) => schedule()));
    WidgetsBinding.instance.addObserver(this);
    // Açılışta bir tur: özetin yedeği ileri kaysın, kapanmış ayar planı
    // temizlesin.
    schedule();
  }

  @visibleForTesting
  ForecastAlertMonitor.forTest(
    this._forecasts,
    this._notifications,
    this._settings,
    this._localizer,
    this._prefs,
    this._wallets,
    this._visibility, {
    required DateTime Function() clock,
  })  : _clock = clock,
        debounce = Duration.zero;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.paused) {
      schedule();
    }
  }

  void schedule() {
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(run()));
  }

  /// Bir tur: ayarlara göre uyarı gönderir ve özeti yeniden planlar.
  Future<void> run() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      final now = _clock();
      final warnings = _settings.isForecastWarningsEnabled;
      final digest = _settings.isWeeklyDigestEnabled;
      if (!digest) await _cancelDigest();
      if (!warnings && !digest) return;

      final period =
          PeriodPreferencesStore(_prefs).read().periodContaining(now);
      final result = await _forecasts.forecast(
        userId: null,
        period: period,
        today: now,
      );
      final l10n = _localizer.l10n;
      if (warnings) await _sendWarning(result, now, l10n);
      if (digest) await _scheduleDigest(result.wallets, now, l10n);
    } catch (e, st) {
      reportError('Gelecek · bildirim turu', e, st);
    } finally {
      _running = false;
      if (_again) {
        _again = false;
        schedule();
      }
    }
  }

  // ------------------------------------------------------------- uyarı

  Future<void> _sendWarning(
      ForecastResult result, DateTime now, AppLocalizations l10n) async {
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    if (_prefs.getString(lastDayKey) == today) return;

    final sent = _readSent();
    final candidates = detectForecastWarnings(result.wallets.values, today: now)
        .where((w) => !sent.contains(w.key));
    final warning = candidates.firstOrNull;
    if (warning == null) return;

    final money = MoneyWriter(
        currency: warning.wallet.currency, visible: _visibility.state);
    final date = AppFormatters.dayMonth.format(warning.date);
    final String title;
    final String body;
    switch (warning.kind) {
      case ForecastWarningKind.cash:
        title = l10n.notifForecastCashTitle;
        body = l10n.notifForecastCashBody(warning.wallet.walletName, date);
      case ForecastWarningKind.budget:
      case ForecastWarningKind.tempBudget:
        final b = warning.budget!;
        final name = b.temp?.name ??
            (buildBreadcrumbs(result.categories)[b.categoryId] ??
                b.categoryId ??
                '');
        title = l10n.notifForecastBudgetTitle;
        body = b.requiredDaily == null
            ? l10n.notifForecastBudgetBodyShort(name, date)
            : l10n.notifForecastBudgetBody(name, date, money(b.requiredDaily!));
    }

    final outcome = await _notifications.showNotification(
      id: ReminderIds.forecastWarning(warning.key),
      title: title,
      body: body,
      // Nakit uyarısının günü Gelecek'in ufkunu uzatır (bkz.
      // [NotificationPayloads.forecastOn]); bütçe satırı ufuktan bağımsız.
      payload: warning.kind == ForecastWarningKind.cash
          ? NotificationPayloads.forecastOn(warning.date)
          : NotificationPayloads.forecast,
    );
    // Teslim edilemediyse (izin kapalı) "gönderildi" sayılmaz: izin
    // açıldığında olay hâlâ geçerliyse bildirilebilsin.
    if (!outcome.delivered) return;
    await _writeSent([...sent, warning.key]);
    await _prefs.setString(lastDayKey, today);
  }

  List<String> _readSent() {
    final raw = _prefs.getString(sentKey);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeSent(List<String> keys) async {
    final trimmed = keys.length > _maxRemembered
        ? keys.sublist(keys.length - _maxRemembered)
        : keys;
    await _prefs.setString(sentKey, jsonEncode(trimmed));
  }

  // ------------------------------------------------------------- özet

  Future<void> _cancelDigest() async {
    await _notifications.cancelNotification(ReminderIds.weeklyDigest);
    await _notifications.cancelNotification(ReminderIds.weeklyDigestStale);
  }

  Future<void> _scheduleDigest(Map<String, WalletForecast> wallets,
      DateTime now, AppLocalizations l10n) async {
    final w = await _digestWallet(wallets);
    if (w == null) return;
    final at = nextDigestTime(now);
    final digest = buildWeeklyDigest(w, from: at);
    await _cancelDigest();
    // "Kayıt yok" yedeği her durumda kurulur: yeni başlayıp unutan kullanıcı
    // tam da onu duymalı. Asıl özet ise söyleyecek bir şey yoksa gitmez —
    // varsayılan açık olduğundan boş bir "haftalık özet" herkese giderdi.
    await _notifications.scheduleNotification(
      id: ReminderIds.weeklyDigestStale,
      title: l10n.notifDigestStaleTitle,
      body: l10n.notifDigestStaleBody,
      scheduledDate: DateTime(at.year, at.month, at.day + 7, at.hour),
      payload: NotificationPayloads.forecast,
      channel: NotificationChannelKind.motivational,
    );
    if (digest.isEmpty) return;
    final money = MoneyWriter(currency: w.currency, visible: _visibility.state);
    final lowest = digest.lowest;
    final parts = <String>[
      if (digest.expectedExpense != null)
        l10n.notifDigestExpense(money(digest.expectedExpense!)),
      if (lowest != null)
        l10n.notifDigestLowest(
            AppFormatters.dayMonth.format(lowest.day), money(lowest.expected)),
      digest.paymentCount == 0
          ? l10n.notifDigestNoPayments
          : l10n.notifDigestPayments(
              digest.paymentCount, money(digest.paymentTotal)),
    ];

    await _notifications.scheduleNotification(
      id: ReminderIds.weeklyDigest,
      title: l10n.notifDigestTitle,
      body: parts.join(' '),
      scheduledDate: at,
      // "En dar gün" ufkun dışında kalabilir: Gelecek o güne uzasın.
      payload: lowest == null
          ? NotificationPayloads.forecast
          : NotificationPayloads.forecastOn(lowest.day),
      channel: NotificationChannelKind.motivational,
    );
  }

  /// Özetin cüzdanı: aktif cüzdan; o bir kartsa ödeme hesabı.
  Future<WalletForecast?> _digestWallet(
      Map<String, WalletForecast> wallets) async {
    List<WalletEntity> all;
    try {
      all = (await _wallets.getAllWallets())
          .fold((_) => const <WalletEntity>[], (v) => v);
    } catch (_) {
      all = const [];
    }
    final active = all.where((w) => w.isActive).firstOrNull ?? all.firstOrNull;
    var id = active?.id;
    final payer = active?.creditCard?.paymentWalletId;
    if (payer != null && wallets.containsKey(payer)) id = payer;
    return wallets[id] ??
        wallets.values.where((w) => !w.isCard).firstOrNull ??
        wallets.values.firstOrNull;
  }

  @disposeMethod
  void dispose() {
    _timer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    WidgetsBinding.instance.removeObserver(this);
  }
}
