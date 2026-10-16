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

class ForecastState extends Equatable {
  final ForecastStatus status;

  /// Tüm cüzdanların tahmini (kimliğe göre).
  final Map<String, WalletForecast> wallets;

  /// Etiketleme için kategoriler.
  final List<CategoryEntity> categories;

  /// Hesaplandığı gün (gece yarısını geçen oturum bayat kalmasın).
  final DateTime? computedFor;

  const ForecastState({
    this.status = ForecastStatus.loading,
    this.wallets = const {},
    this.categories = const [],
    this.computedFor,
  });

  @override
  List<Object?> get props => [status, wallets, categories, computedFor];
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
      emit(ForecastState(
        status: ForecastStatus.ready,
        wallets: result.wallets,
        categories: result.categories,
        computedFor: DateTime(now.year, now.month, now.day),
      ));
    } catch (e, st) {
      reportError('Gelecek · tahmin', e, st);
      if (isClosed || gen != _generation) return;
      emit(ForecastState(
        status: ForecastStatus.failed,
        wallets: state.wallets,
        categories: state.categories,
        computedFor: state.computedFor,
      ));
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
