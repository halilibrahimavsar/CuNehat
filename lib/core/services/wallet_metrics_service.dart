import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/services/reminder_sync_service.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/debt_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/receivable_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/investments/domain/repositories/goal_repository.dart';
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

/// Defter değişmezi — cüzdan bakiyesini hesaplayan **TEK** formül:
/// `balance = openingBalance + Σ signed(işlemler)`.
///
/// İki aşamalı kuruş yuvarlaması bilinçlidir: önce toplam, sonra sonuç.
/// Aşamalardan biri atlanırsa aynı defter iki farklı kuruş verebilir.
///
/// [WalletMetricsService.syncBalance] ve yedekten geri yükleme (defteri
/// kutulara doğrudan yazdığı için servise uğramaz) aynı formülü paylaşsın
/// diye serbest fonksiyon.
double deriveWalletBalance({
  required double openingBalance,
  required Iterable<({bool isIncome, double amount})> movements,
}) {
  final sum = roundToCents(movements.fold<double>(
    0.0,
    (total, m) => total + (m.isIncome ? m.amount : -m.amount),
  ));
  return roundToCents(openingBalance + sum);
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

/// Nakit hareketi yazımının sonucu.
///
/// [ok] eski `bool` sözleşmesinin aynısı (hata bacağında `false`, fırlatmaz).
/// [transactionIds] yazılan sistem işlemlerinin kimlikleridir; silme akışları
/// bunları saklayıp "geri al"da o kayıtları temizler.
@immutable
class CashWriteResult {
  final bool ok;
  final List<String> transactionIds;

  const CashWriteResult({
    required this.ok,
    this.transactionIds = const <String>[],
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
  final GoalRepository goalRepository;
  final TransactionsRepository transactionsRepository;
  final TransactionsChangedNotifier transactionsChangedNotifier;

  /// Cüzdan silinirken borçların PLANLANMIŞ hatırlatmalarını da düşürmek için.
  ///
  /// [purgeWalletData] borçları `DeleteDebtUsecase`'i atlayıp doğrudan
  /// repository'den siliyor; iptal ise o usecase'in içindeydi. Sonuç: silinmiş
  /// cüzdanın borcu OS'ta planlı kalıyordu ve `syncAllDebtReminders` yalnız
  /// VAR OLAN borçları gezdiği için o kayda bir daha hiç uğranmıyordu — yani
  /// öksüz alarm hiçbir açılışta temizlenmiyordu.
  final ReminderSyncService reminderSync;

  WalletMetricsService({
    required this.walletRepository,
    required this.debtRepository,
    required this.receivableRepository,
    required this.investmentRepository,
    required this.goalRepository,
    required this.transactionsRepository,
    required this.transactionsChangedNotifier,
    required this.reminderSync,
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
  }) async {
    final result = await _writeCashMovements(
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
    return result.ok;
  }

  /// Birden çok nakit hareketini TEK defter senkronuyla yazar.
  ///
  /// Bir borcun silinmesi gibi işlemler N+1 ters kayıt üretir; bunları tek tek
  /// [recordCashMovement] ile yazmak her kayıt için ayrı bir defter okuma +
  /// bakiye yazma turu demekti. Burada işlemler yazılır, dinleyiciler bir kez
  /// uyarılır ve bakiye bir kez yeniden hesaplanır.
  ///
  /// Herhangi bir işlem yazılamazsa `ok == false` döner; yazılabilenler geri
  /// alınmaz — bakiye zaten defterden türetildiği için tutarlı kalır.
  ///
  /// Dönen [CashWriteResult.transactionIds] "geri al" için zorunludur: silme
  /// akışlarının yazdığı ters kayıtlar sistem işlemi olduğu için UI'dan
  /// silinemez, geri alma da onları id ile bulmak zorundadır (tag+tarih+tutar
  /// eşleşmesi aynı gün aynı tutarlı iki hareketi ayırt edemez).
  Future<CashWriteResult> recordCashMovements({
    required String walletId,
    required List<CashMovement> entries,
  }) =>
      _serialized(
        walletId,
        () => _writeCashMovements(walletId: walletId, entries: entries),
      );

  Future<CashWriteResult> _writeCashMovements({
    required String walletId,
    required List<CashMovement> entries,
  }) async {
    if (entries.isEmpty) return const CashWriteResult(ok: true);

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
      //
      // SIRA ÖNEMLİ: önce bakiye türetilir, SONRA haber verilir. Ters sırada
      // (eski davranış) bildirimi alan her dinleyici — işlem/borç/alacak/
      // yatırım blocları, bütçe yükleyici, bütçe uyarı monitörü — cüzdanı
      // senkron ÖNCESİ bakiyesiyle okuyordu. Diğer tüm yazım yolları
      // (transaction_bloc, bank_import_cubit, pending_recurring_bloc) zaten
      // bu sıradaydı; yalnız burası ters duruyordu.
      final synced = await _syncBalanceImpl(walletId);
      transactionsChangedNotifier.notify();
      return CashWriteResult(
        ok: allWritten && synced,
        // Yazım başarısızsa id vermek yanıltıcı olurdu: geri alma var olmayan
        // kayıtları silmeye çalışırdı.
        transactionIds: allWritten
            ? [for (final t in transactions) t.id!]
            : const <String>[],
      );
    } catch (e) {
      debugPrint('recordCashMovement başarısız: $e');
      return const CashWriteResult(ok: false);
    }
  }

  /// Yazılmış nakit hareketlerini kimlikleriyle GERİ ALIR ve etkilenen
  /// cüzdanların bakiyesini defterden yeniden türetir.
  ///
  /// **Neden gerekli:** kuplajla yazılan her satır `isSystem: true`'dur ve
  /// UI'dan silinemez (bilerek — defterle desync olmasın). Bunun bedeli,
  /// arkasında düzenlenebilir bir KAYIT olmayan hareketlerin — transferin iki
  /// bacağı gibi — hiçbir şekilde düzeltilememesiydi: yanlış tutar girilen
  /// bir transfer kullanıcıda kalıcı olarak yanlış bakiye bırakıyordu.
  ///
  /// Silme kuyruk DIŞINDA yapılır, senkron ise cüzdan başına kuyruğa girer;
  /// böylece eşzamanlı bir yazım bayat okumayla ezilmez.
  ///
  /// Herhangi bir silme ya da senkron başarısızsa `false` döner; silinebilenler
  /// geri yazılmaz — bakiye zaten defterden türediği için tutarlı kalır.
  Future<bool> removeCashMovements({
    required List<String> transactionIds,
    required Set<String> walletIds,
  }) async {
    if (transactionIds.isEmpty) return true;

    var ok = true;
    for (final id in transactionIds) {
      final result = await transactionsRepository.deleteTransaction(id);
      ok = result.fold(
        (failure) {
          debugPrint(
              'removeCashMovements: kayıt silinemedi: ${failure.message}');
          return false;
        },
        (_) => ok,
      );
    }

    transactionsChangedNotifier.notify();
    for (final walletId in walletIds) {
      ok = await syncBalance(walletId) && ok;
    }
    return ok;
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
            final newBalance = deriveWalletBalance(
              openingBalance: wallet.openingBalance,
              movements: [
                for (final t in txs) (isIncome: t.isIncome, amount: t.amount),
              ],
            );

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

  /// Cüzdan silinirken o cüzdana bağlı tüm kayıtları (işlem/borç/alacak/
  /// yatırım/hedef) temizler; yetim veri kalmasını önler.
  ///
  /// [userId] VERİLMEZSE cüzdanın kendisinden okunur. Çağıranın elindeki
  /// listeye güvenmek, o liste yoksa (bloc state'i `WalletLoadedSt` değilken)
  /// ya da bayatken temizliğin sessizce ATLANMASINA yol açıyordu: cüzdan yine
  /// siliniyor, işlemleri/borçları/alacakları/yatırımları/hedefleri ise
  /// sonsuza dek kutularda kalıyordu — üstelik tüm-cüzdan taramalarına
  /// (`countByTags`, `retagTransactions`) girmeye devam ederek.
  ///
  /// Her şey silinebildiyse `true`. Çağıran, `false` iken cüzdanı silmemeli:
  /// yarım temizlik + silinmiş cüzdan = geri dönüşü olmayan yetim veri.
  Future<bool> purgeWalletData(String walletId, [String? userId]) =>
      _serialized(walletId, () => _purgeWalletDataImpl(walletId, userId));

  Future<bool> _purgeWalletDataImpl(
      String walletId, String? givenUserId) async {
    var ok = true;

    var userId = givenUserId;
    if (userId == null) {
      final walletResult = await walletRepository.getWalletById(walletId);
      userId = walletResult.fold((_) => null, (w) => w?.userId);
    }
    if (userId == null) {
      debugPrint('purgeWalletData: cüzdan okunamadı, temizlik yapılmadı');
      return false;
    }

    final txsResult = await transactionsRepository.getTransactions(
      userId: userId,
      walletId: walletId,
    );
    await txsResult.fold(
      (failure) async {
        debugPrint('WalletMetricsService: ${failure.message}');
        ok = false;
      },
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
      (failure) async {
        debugPrint('WalletMetricsService: ${failure.message}');
        ok = false;
      },
      (debts) async {
        for (final d in debts) {
          if (d.id == null) continue;
          // Önce alarmı düşür, sonra kaydı sil: sıra tersse ve silme
          // patlarsa kayıt duruyor ama hatırlatması iptal edilmiş olurdu.
          await reminderSync.cancelDebtReminders(d.id!);
          await debtRepository.deleteDebt(d.id!);
        }
      },
    );

    final receivablesResult =
        await receivableRepository.getReceivablesByWalletId(walletId);
    await receivablesResult.fold(
      (failure) async {
        debugPrint('WalletMetricsService: ${failure.message}');
        ok = false;
      },
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
      (failure) async {
        debugPrint('WalletMetricsService: ${failure.message}');
        ok = false;
      },
      (investments) async {
        for (final inv in investments) {
          if (inv.id != null) {
            await investmentRepository.deleteInvestment(inv.id!);
          }
        }
      },
    );

    // Birikim hedefleri de cüzdana bağlı: üyeleri silinmiş bir hedef
    // listede "%0" olarak kalırdı.
    final goalsResult = await goalRepository.getGoals(
      userId: userId,
      walletId: walletId,
    );
    await goalsResult.fold(
      (failure) async {
        debugPrint('WalletMetricsService: ${failure.message}');
        ok = false;
      },
      (goals) async {
        for (final goal in goals) {
          await goalRepository.deleteGoal(goal.id);
        }
      },
    );

    return ok;
  }
}
