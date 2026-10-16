import 'dart:async';

import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/features/forecast/data/forecast_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_bloc/flutter_bloc.dart';

enum ForecastStatus { loading, ready, failed }

/// Sayfanın kapsamı: aktif cüzdan ya da tüm cüzdanların birleşimi.
enum ForecastScope { wallet, all }

class ForecastState extends Equatable {
  final ForecastStatus status;

  /// Tüm cüzdanların tahmini (kimliğe göre).
  final Map<String, WalletForecast> wallets;

  /// Etiketleme için kategoriler.
  final List<CategoryEntity> categories;

  /// Hesaplandığı gün (gece yarısını geçen oturum bayat kalmasın).
  final DateTime? computedFor;

  final ForecastScope scope;

  /// "Tüm cüzdanlar" için birim → görüntü birimi kurları.
  final Map<String, double> rates;

  const ForecastState({
    this.status = ForecastStatus.loading,
    this.wallets = const {},
    this.categories = const [],
    this.computedFor,
    this.scope = ForecastScope.wallet,
    this.rates = const {},
  });

  ForecastState copyWith({
    ForecastStatus? status,
    Map<String, WalletForecast>? wallets,
    List<CategoryEntity>? categories,
    DateTime? computedFor,
    ForecastScope? scope,
    Map<String, double>? rates,
  }) =>
      ForecastState(
        status: status ?? this.status,
        wallets: wallets ?? this.wallets,
        categories: categories ?? this.categories,
        computedFor: computedFor ?? this.computedFor,
        scope: scope ?? this.scope,
        rates: rates ?? this.rates,
      );

  @override
  List<Object?> get props =>
      [status, wallets, categories, computedFor, scope, rates];
}

/// Gelecek sayfasının durumu. Defter ya da bütçe değişince kendini yeniler:
/// alt görünümler kaydırma yığınında canlı kaldığı için `initState` yeniden
/// çalışmaz (Rapor'daki bayat bütçe hatasının dersi).
class ForecastCubit extends Cubit<ForecastState> {
  final ForecastService _service;
  final String userId;

  /// Dönemi her yüklemede taze sorar: kullanıcı dönem birimini Ayarlar'dan
  /// değiştirmiş olabilir.
  final DateTimeRange Function() periodOf;
  final DateTimeRange? Function()? previousPeriodOf;

  final DateTime Function() _clock;
  final List<StreamSubscription<Object?>> _subs = [];

  ForecastCubit(
    this._service, {
    required this.userId,
    required this.periodOf,
    this.previousPeriodOf,
    TransactionsChangedNotifier? transactions,
    BudgetsChangedNotifier? budgets,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        super(const ForecastState()) {
    if (transactions != null) {
      _subs.add(transactions.stream.listen((_) => load()));
    }
    if (budgets != null) _subs.add(budgets.stream.listen((_) => load()));
  }

  int _generation = 0;

  Future<void> load() async {
    final gen = ++_generation;
    final now = _clock();
    try {
      final result = await _service.forecast(
        userId: userId,
        period: periodOf(),
        previousPeriod: previousPeriodOf?.call(),
        today: now,
      );
      // Üst üste gelen yenilemelerde yalnız EN SON istek yazar.
      if (isClosed || gen != _generation) return;
      emit(state.copyWith(
        status: ForecastStatus.ready,
        wallets: result.wallets,
        categories: result.categories,
        computedFor: DateTime(now.year, now.month, now.day),
      ));
      if (state.scope == ForecastScope.all) await _loadRates();
    } catch (e, st) {
      reportError('Gelecek · tahmin', e, st);
      if (isClosed || gen != _generation) return;
      emit(state.copyWith(status: ForecastStatus.failed));
    }
  }

  /// Görüntü birimi: tüm cüzdanlar görünümünde toplamların birimi.
  String? displayCurrency;

  /// Kapsamı değiştirir; "tüm cüzdanlar"a geçişte kurlar yüklenir.
  Future<void> setScope(ForecastScope scope, {required String currency}) async {
    displayCurrency = currency;
    emit(state.copyWith(scope: scope));
    if (scope == ForecastScope.all) await _loadRates();
  }

  Future<void> _loadRates() async {
    final currency = displayCurrency;
    if (currency == null) return;
    final needed = {
      for (final w in state.wallets.values)
        if (w.currency != currency) w.currency,
    };
    if (needed.isEmpty) return;
    try {
      final rates = await _service.ratesTo(currency, needed);
      if (isClosed) return;
      emit(state.copyWith(rates: rates));
    } catch (e, st) {
      reportError('Gelecek · kurlar', e, st);
    }
  }

  /// Gün değiştiyse yeniden hesaplar (sayfa göründüğünde çağrılır).
  void refreshIfStale() {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    if (state.computedFor != today) load();
  }

  @override
  Future<void> close() {
    for (final s in _subs) {
      s.cancel();
    }
    return super.close();
  }
}
