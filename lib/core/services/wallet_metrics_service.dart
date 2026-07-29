import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/debt_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/receivable_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Kuplaj ile otomatik oluşturulan nakit işlemlerinin sabit etiketleri (tag).
class CashMovementTags {
  static const String debt = 'Borç';
  static const String debtPayment = 'Borç Ödemesi';
  static const String receivable = 'Alacak';
  static const String receivableCollection = 'Alacak Tahsilatı';
  static const String investmentBuy = 'Yatırım Alımı';
  static const String investmentSell = 'Yatırım Satışı';
  static const String investmentCorrection = 'Yatırım Düzeltmesi';
  static const String transfer = 'Transfer';

  /// Tüm sistem etiketleri. Kategori adları bunlarla çakışamaz: bütçe
  /// harcaması ve rapor kırılımı `tag == categoryId` ile eşleştiğinden,
  /// aynı adlı kullanıcı kategorisi sistem hareketlerini kendine sayardı.
  static const List<String> all = [
    debt,
    debtPayment,
    receivable,
    receivableCollection,
    investmentBuy,
    investmentSell,
    investmentCorrection,
    transfer,
  ];

  /// [name] sistem etiketlerinden biriyle (büyük/küçük harf duyarsız)
  /// çakışıyor mu? Kategori oluşturma/yeniden adlandırma bunu reddeder.
  static bool isReserved(String name) {
    final n = name.trim().toLowerCase();
    return all.any((t) => t.toLowerCase() == n);
  }
}

/// Deftere yazılacak tek bir nakit hareketi.
///
/// [date] geçmişteki bir kaydı TERSİNE ÇEVİRİRKEN kritik: ters kayıt, iptal
/// ettiği hareketin kendi tarihine yazılmazsa bakiye doğru çıksa bile o ayın
/// raporuna hiç yaşanmamış bir gelir/gider düşer. `null` ise "şimdi".
class CashMovement {
  final String userId;
  final double amount;
  final bool isIncome;
  final String title;
  final String tag;
  final DateTime? date;

  const CashMovement({
    required this.userId,
    required this.amount,
    required this.isIncome,
    required this.title,
    required this.tag,
    this.date,
  });
}

/// Kasıtlı cross-feature orkestratör: cüzdan defteri (balance/debt/credit/
/// investment) birden çok feature'ın repolarından beslenir; bu yüzden core'da
/// yaşar ve feature repolarına bağımlılığı mimari bir kabul olarak belgelidir.
@lazySingleton
class WalletMetricsService {
  final WalletRepository walletRepository;
  final DebtRepository debtRepository;
  final ReceivableRepository receivableRepository;
  final InvestmentRepository investmentRepository;
  final TransactionsRepository transactionsRepository;
  final TransactionsChangedNotifier transactionsChangedNotifier;

  WalletMetricsService({
    required this.walletRepository,
    required this.debtRepository,
    required this.receivableRepository,
    required this.investmentRepository,
    required this.transactionsRepository,
    required this.transactionsChangedNotifier,
  });

  /// Cüzdan başına yazma kuyruğu: aynı cüzdanın bakiye/metrik
  /// okuma-değiştirme-yazma akışları sıralanır; eşzamanlı bloc akışları
  /// (örn. borç handler'ı + WalletBloc'un fire-and-forget sync'i)
  /// birbirinin yazımını bayat okumayla ezemez.
  final Map<String, Future<void>> _walletQueues = {};

  /// Re-entrancy kuralı: yalnız PUBLIC metodlar kuyruğa girer; `_xxxImpl`
  /// gövdeleri girmez. `recordCashMovement` içinden `_syncBalanceImpl`
  /// çağrısı bu sayede kendi kuyruğunu beklemez (deadlock olmaz).
  Future<T> _serialized<T>(String walletId, Future<T> Function() op) {
    final tail = _walletQueues[walletId] ?? Future<void>.value();
    final result = tail.then((_) => op());
    // Kuyruk ucu hatayı yutar; hata çağırana `result` üzerinden gider.
    final next = result.then<void>((_) {}, onError: (_) {});
    _walletQueues[walletId] = next;
    next.whenComplete(() {
      if (identical(_walletQueues[walletId], next)) {
        _walletQueues.remove(walletId);
      }
    });
    return result;
  }

  /// Nakit kuplajı: gerçek bir işlem (transaction) kaydeder VE bakiyeyi
  /// defterden yeniden hesaplar. Borç/yatırım/alacak operasyonları bunu
  /// çağırır ki nakit hareketleri işlem geçmişinde görünür ve `balance`
  /// ile tutarlı kalsın. Başarısızlıkta `false` döner, fırlatmaz.
  Future<bool> recordCashMovement({
    required String walletId,
    required String userId,
    required double amount,
    required bool isIncome,
    required String title,
    required String tag,
    DateTime? date,
  }) =>
      _serialized(
        walletId,
        () => _recordCashMovementImpl(
          walletId: walletId,
          userId: userId,
          amount: amount,
          isIncome: isIncome,
          title: title,
          tag: tag,
          date: date,
        ),
      );

  Future<bool> _recordCashMovementImpl({
    required String walletId,
    required String userId,
    required double amount,
    required bool isIncome,
    required String title,
    required String tag,
    DateTime? date,
  }) =>
      _writeCashMovements(
        walletId: walletId,
        entries: [
          CashMovement(
            userId: userId,
            amount: amount,
            isIncome: isIncome,
            title: title,
            tag: tag,
            date: date,
          ),
        ],
      );

  /// Birden çok nakit hareketini TEK defter senkronuyla yazar.
  ///
  /// Bir borcun silinmesi gibi işlemler N+1 ters kayıt üretir; bunları tek tek
  /// [recordCashMovement] ile yazmak her kayıt için ayrı bir defter okuma +
  /// bakiye yazma turu demekti. Burada işlemler yazılır, dinleyiciler bir kez
  /// uyarılır ve bakiye bir kez yeniden hesaplanır.
  ///
  /// Herhangi bir işlem yazılamazsa `false` döner; yazılabilenler geri
  /// alınmaz — bakiye zaten defterden türetildiği için tutarlı kalır.
  Future<bool> recordCashMovements({
    required String walletId,
    required List<CashMovement> entries,
  }) =>
      _serialized(
        walletId,
        () => _writeCashMovements(walletId: walletId, entries: entries),
      );

  Future<bool> _writeCashMovements({
    required String walletId,
    required List<CashMovement> entries,
  }) async {
    if (entries.isEmpty) return true;

    try {
      final transactions = [
        for (final e in entries)
          TransactionEntity(
            id: UidGenerator.generateV7(),
            userId: e.userId,
            walletId: walletId,
            title: e.title,
            tag: e.tag,
            // Kuplajla gelen tutarlar (borç farkı, satış bedeli vb.)
            // hesaplanmış olabilir; deftere her zaman kuruş-temiz yazılır.
            amount: roundToCents(e.amount),
            date: e.date ?? DateTime.now(),
            type: e.isIncome
                ? TransactionTypeModel.income
                : TransactionTypeModel.expense,
            isSystem: true,
          ),
      ];

      // TEK toplu yazım. Kayıt başına ayrı `addTransaction` çağrısı, her biri
      // kendi await turu ve disk flush'ı olan N tur demekti: 36 taksitli bir
      // borcun silinmesi 37 ardışık yazım yapıyor, silme diyaloğu o süre
      // boyunca bloklu bekliyordu.
      final addResult = await transactionsRepository.addTransactions(
        transactions,
      );
      final allWritten = addResult.fold(
        (failure) {
          debugPrint(
              'recordCashMovement: işlemler yazılamadı: ${failure.message}');
          return false;
        },
        (_) => true,
      );

      // Kuplajla yazılan sistem işlemi de defteri değiştirir; işlem sayfası
      // ve diğer dinleyiciler canlı yenilensin.
      transactionsChangedNotifier.notify();
      final synced = await _syncBalanceImpl(walletId);
      return allWritten && synced;
    } catch (e) {
      debugPrint('recordCashMovement başarısız: $e');
      return false;
    }
  }

  /// Bakiyeyi işlemlerden yeniden hesaplar; cüzdan bakiyesinin TEK yazım yolu.
  /// `balance = openingBalance + Σ signed(tüm işlemler)`.
  /// Başarı ya da no-op'ta `true`, herhangi bir hata bacağında `false` döner.
  Future<bool> syncBalance(String walletId) =>
      _serialized(walletId, () => _syncBalanceImpl(walletId));

  Future<bool> _syncBalanceImpl(String walletId) async {
    final result = await walletRepository.getWalletById(walletId);
    return result.fold(
      (failure) async {
        debugPrint('syncBalance: cüzdan okunamadı: ${failure.message}');
        return false;
      },
      (wallet) async {
        if (wallet == null) return false;

        final txsResult = await transactionsRepository.getTransactions(
          userId: wallet.userId,
          walletId: walletId,
        );

        return txsResult.fold(
          (failure) async {
            debugPrint('syncBalance: işlemler okunamadı: ${failure.message}');
            return false;
          },
          (txs) async {
            final txSum = roundToCents(txs.fold<double>(
              0.0,
              (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
            ));

            final newBalance = roundToCents(wallet.openingBalance + txSum);

            // Tutarlıysa hiç yazma (yaygın durum; gereksiz emit/yazma döngüsünü önler).
            if (moneyEquals(wallet.balance, newBalance)) {
              return true;
            }

            // Kuyruk DIŞI yazımları (debt/credit/investment metrikleri,
            // WalletBloc cüzdan düzenlemesi) ezmemek için yazmadan hemen
            // önce güncel cüzdanı tekrar oku ve yalnız bakiye alanlarını
            // taze kayda uygula.
            final freshResult = await walletRepository.getWalletById(walletId);
            return freshResult.fold(
              (failure) async {
                debugPrint(
                    'syncBalance: taze cüzdan okunamadı: ${failure.message}');
                return false;
              },
              (fresh) async {
                // Cüzdan iki okuma arasında silindiyse bayat kopyayı geri
                // yazma: put silinmiş cüzdanı diriltir. Senkron iptal edilir.
                if (fresh == null) return false;
                final writeResult = await walletRepository.updateWallet(
                  fresh.copyWith(balance: newBalance),
                );
                return writeResult.fold(
                  (failure) {
                    debugPrint(
                        'syncBalance: bakiye yazılamadı: ${failure.message}');
                    return false;
                  },
                  (_) => true,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> syncDebt(String walletId) =>
      _serialized(walletId, () => _syncDebtImpl(walletId));

  Future<void> _syncDebtImpl(String walletId) async {
    final debtsResult = await debtRepository.getDebtsByWalletId(walletId);
    await debtsResult.fold(
      (failure) async => debugPrint('WalletMetricsService: ${failure.message}'),
      (debts) async {
        final totalDebt = roundToCents(debts
            .where((debt) => !debt.isPaid)
            .fold<double>(0.0, (sum, debt) => sum + debt.remainingAmount));

        // Cüzdanı toplamadan SONRA, yazmadan hemen önce oku: kuyruk dışı
        // yazımların (balance/opening) üzerine bayat kopya yazılmasın.
        final result = await walletRepository.getWalletById(walletId);
        await result.fold(
          (failure) async =>
              debugPrint('WalletMetricsService: ${failure.message}'),
          (wallet) async {
            if (wallet == null) return;
            if (!moneyEquals(wallet.debt, totalDebt)) {
              await walletRepository
                  .updateWallet(wallet.copyWith(debt: totalDebt));
            }
          },
        );
      },
    );
  }

  Future<void> syncCredit(String walletId) =>
      _serialized(walletId, () => _syncCreditImpl(walletId));

  Future<void> _syncCreditImpl(String walletId) async {
    final receivablesResult =
        await receivableRepository.getReceivablesByWalletId(walletId);
    await receivablesResult.fold(
      (failure) async => debugPrint('WalletMetricsService: ${failure.message}'),
      (receivables) async {
        final totalCredit = roundToCents(receivables
            .where((r) => !r.isPaid)
            .fold<double>(0.0, (sum, r) => sum + r.amount));

        // Bkz. _syncDebtImpl: yazmadan hemen önce taze oku.
        final result = await walletRepository.getWalletById(walletId);
        await result.fold(
          (failure) async =>
              debugPrint('WalletMetricsService: ${failure.message}'),
          (wallet) async {
            if (wallet == null) return;
            if (!moneyEquals(wallet.credit, totalCredit)) {
              await walletRepository
                  .updateWallet(wallet.copyWith(credit: totalCredit));
            }
          },
        );
      },
    );
  }

  Future<void> syncInvestment(String walletId) =>
      _serialized(walletId, () => _syncInvestmentImpl(walletId));

  Future<void> _syncInvestmentImpl(String walletId) async {
    final result = await walletRepository.getWalletById(walletId);
    await result.fold(
      (failure) async => debugPrint('WalletMetricsService: ${failure.message}'),
      (wallet) async {
        if (wallet == null) return;

        final invResult = await investmentRepository.getInvestments(
          userId: wallet.userId,
          walletId: walletId,
        );

        final totalInvestment = invResult.fold(
          (failure) => 0.0,
          (investments) => roundToCents(investments.fold<double>(
            0.0,
            (sum, item) => sum + item.currentValue,
          )),
        );

        // Bkz. _syncDebtImpl: yazmadan hemen önce taze oku (ilk okuma
        // yalnız userId içindi).
        final freshResult = await walletRepository.getWalletById(walletId);
        await freshResult.fold(
          (failure) async =>
              debugPrint('WalletMetricsService: ${failure.message}'),
          (fresh) async {
            // Bkz. _syncBalanceImpl: silinmiş cüzdanı bayat kopyayla diriltme.
            if (fresh == null) return;
            if (!moneyEquals(fresh.investment, totalInvestment)) {
              await walletRepository
                  .updateWallet(fresh.copyWith(investment: totalInvestment));
            }
          },
        );
      },
    );
  }

  /// Cüzdan silinirken o cüzdana bağlı tüm kayıtları (işlem/borç/alacak/yatırım)
  /// temizler; yetim veri kalmasını önler.
  Future<void> purgeWalletData(String walletId, String userId) =>
      _serialized(walletId, () => _purgeWalletDataImpl(walletId, userId));

  Future<void> _purgeWalletDataImpl(String walletId, String userId) async {
    final txsResult = await transactionsRepository.getTransactions(
      userId: userId,
      walletId: walletId,
    );
    await txsResult.fold(
      (failure) async => debugPrint('WalletMetricsService: ${failure.message}'),
      (txs) async {
        for (final t in txs) {
          if (t.id != null) {
            await transactionsRepository.deleteTransaction(t.id!);
          }
        }
      },
    );

    final debtsResult = await debtRepository.getDebtsByWalletId(walletId);
    await debtsResult.fold(
      (failure) async => debugPrint('WalletMetricsService: ${failure.message}'),
      (debts) async {
        for (final d in debts) {
          if (d.id != null) await debtRepository.deleteDebt(d.id!);
        }
      },
    );

    final receivablesResult =
        await receivableRepository.getReceivablesByWalletId(walletId);
    await receivablesResult.fold(
      (failure) async => debugPrint('WalletMetricsService: ${failure.message}'),
      (receivables) async {
        for (final r in receivables) {
          if (r.id != null) await receivableRepository.deleteReceivable(r.id!);
        }
      },
    );

    final invResult = await investmentRepository.getInvestments(
      userId: userId,
      walletId: walletId,
    );
    await invResult.fold(
      (failure) async => debugPrint('WalletMetricsService: ${failure.message}'),
      (investments) async {
        for (final inv in investments) {
          if (inv.id != null) {
            await investmentRepository.deleteInvestment(inv.id!);
          }
        }
      },
    );
  }
}
