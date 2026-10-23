import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/budgets/domain/repositories/temp_budget_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/debt_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/receivable_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/forecast/domain/forecast_engine.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/repositories/goal_repository.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:injectable/injectable.dart';

/// [ForecastService.forecast]'in sonucu: cüzdan tahminleri + etiketleme için
/// kategori listesi (ikinci bir okuma yapılmasın).
class ForecastResult {
  final Map<String, WalletForecast> wallets;
  final List<CategoryEntity> categories;

  const ForecastResult({required this.wallets, required this.categories});
}

/// Tahminin girdisini depolardan toplar ve motoru çalıştırır.
///
/// Kullanıcının TÜM cüzdanları okunur, aktif olanın tahmini için bile: kart
/// ödemesi kartın ödeme hesabına çıkış olarak düşer, yani düz bir hesabın
/// yolculuğu ona bağlı kartların defterine de bakar.
///
/// Bir parçanın okunamaması tahmini düşürmez: o parça boş kalır ve hata
/// günlüğüne yazılır (bkz. [reportError]). Tahmin yarım kalsa da yön
/// gösterir; tamamen hata ekranı göstermek kullanıcıya hiçbir şey söylemez.
@lazySingleton
class ForecastService {
  final WalletRepository _wallets;
  final TransactionsRepository _transactions;
  final RecurringTransactionRepository _recurring;
  final DebtRepository _debts;
  final ReceivableRepository _receivables;
  final BudgetRepository _budgets;
  final TempBudgetRepository _tempBudgets;
  final GoalRepository _goals;
  final InvestmentRepository _investments;
  final CategoryRepository _categories;
  final ExchangeRateService _rates;

  ForecastService(
    this._wallets,
    this._transactions,
    this._recurring,
    this._debts,
    this._receivables,
    this._budgets,
    this._tempBudgets,
    this._goals,
    this._investments,
    this._categories,
    this._rates,
  );

  /// [currencies] → [currency] kurları ("Tüm cüzdanlar" için; şu an
  /// kullanılmıyor, tüm cüzdan raporu için tutuluyor — bkz.
  /// `combineForecasts`). Kuru
  /// alınamayan birim haritada YOKTUR (çağıran o cüzdanı dışarıda bırakır).
  /// Önce ağ denenir (önbellek tazeyse ağa çıkmaz), olmazsa bayat önbellek.
  Future<Map<String, double>> ratesTo(
      String currency, Iterable<String> currencies) async {
    final out = <String, double>{};
    for (final c in currencies.toSet()) {
      if (c == currency) continue;
      double? r;
      try {
        r = await _rates.rateBetween(c, currency);
      } catch (e, st) {
        reportError('Gelecek · kur', e, st);
      }
      r ??= _rates.cachedRateBetween(c, currency);
      if (r != null && r > 0) out[c] = r;
    }
    return out;
  }

  /// [userId]'nin tüm cüzdanlarının tahmini, kimliğe göre. [userId] `null`
  /// ise cihazdaki TÜM cüzdanlar (uygulama düzeyi bildirim monitörü; her
  /// cüzdan kendi sahibinin kimliğiyle okunur).
  ///
  /// [walletId] verilirse yalnız o cüzdan için gereken girdiler okunur: o
  /// cüzdan + bütün kart cüzdanları (kart ödemesinin ödeyen bacağı kartın
  /// girdisinden üretilir, bkz. [ForecastEngine.projectAll]). Sonuçta kart
  /// cüzdanlarının tahmini de bulunur; çağıran yalnız istediğini okur.
  Future<ForecastResult> forecast({
    required String? userId,
    required DateTimeRange period,
    DateTimeRange? previousPeriod,
    DateTime? today,
    int horizonDays = 30,
    String? walletId,
  }) async {
    final wallets = await _read<List<WalletEntity>>(
        'cüzdanlar',
        () => userId == null
            ? _wallets.getAllWallets()
            : _wallets.getWallets(userId),
        const []);
    final templates = await _read<List<RecurringTransactionEntity>>(
        'düzenli şablonlar', _recurring.getAllTemplates, const []);
    final debts =
        await _read<List<DebtEntity>>('borçlar', _debts.getAllDebts, const []);

    List<CategoryEntity> categories;
    try {
      categories = await _categories.getAllCategories();
    } catch (e, st) {
      reportError('Gelecek · kategoriler', e, st);
      categories = const [];
    }

    final inputs = <WalletForecastInput>[];
    for (final w in wallets) {
      final id = w.id;
      if (id == null) continue;
      if (walletId != null && id != walletId && w.creditCard == null) {
        continue;
      }
      final uid = userId ?? w.userId;
      inputs.add(WalletForecastInput(
        wallet: w,
        ledger: await _read<List<TransactionEntity>>(
            'defter',
            () => _transactions.getTransactions(userId: uid, walletId: id),
            const []),
        templates: [
          for (final t in templates)
            if (t.walletId == id) t,
        ],
        debts: [
          for (final d in debts)
            if (d.walletId == id) d,
        ],
        receivables: await _read<List<ReceivableEntity>>('alacaklar',
            () => _receivables.getReceivablesByWalletId(id), const []),
        budgets: await _read<List<BudgetEntity>>(
            'bütçeler', () => _budgets.getBudgets(id), const []),
        tempBudgets: await _read<List<TempBudgetEntity>>(
            'tek seferlik bütçeler',
            () => _tempBudgets.getTempBudgets(id), const []),
        goals: await _read<List<GoalEntity>>('hedefler',
            () => _goals.getGoals(userId: uid, walletId: id), const []),
        investments: await _read<List<InvestmentEntity>>(
            'yatırımlar',
            () => _investments.getInvestments(userId: uid, walletId: id),
            const []),
      ));
    }

    return ForecastResult(
      wallets: ForecastEngine(
        today: today ?? DateTime.now(),
        period: period,
        previousPeriod: previousPeriod,
        horizonDays: horizonDays,
        categories: categories,
      ).projectAll(inputs, currencies: {
        for (final w in wallets)
          if (w.id != null) w.id!: w.currency,
      }),
      categories: categories,
    );
  }

  /// Either döndüren okuma: hata ya da istisna → [fallback] + günlük.
  Future<T> _read<T>(
    String what,
    Future<Either<Object, T>> Function() call,
    T fallback,
  ) async {
    try {
      final result = await call();
      return result.fold((failure) {
        reportError('Gelecek · $what', failure, StackTrace.current);
        return fallback;
      }, (value) => value);
    } catch (e, st) {
      reportError('Gelecek · $what', e, st);
      return fallback;
    }
  }
}
