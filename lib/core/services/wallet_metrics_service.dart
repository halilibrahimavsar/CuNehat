import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repository/debt_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repository/receivable_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_repository.dart';
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

  WalletMetricsService({
    required this.walletRepository,
    required this.debtRepository,
    required this.receivableRepository,
    required this.investmentRepository,
    required this.transactionsRepository,
  });

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
  }) async {
    final tx = TransactionEntity(
      id: UidGenerator.generateV7(),
      userId: userId,
      walletId: walletId,
      title: title,
      tag: tag,
      amount: amount,
      date: date ?? DateTime.now(),
      type:
          isIncome ? TransactionTypeModel.income : TransactionTypeModel.expense,
      isSystem: true,
    );
    try {
      // openingBalance null olan eski cüzdanı YENİ işlemi eklemeden önce
      // geri doldur; yoksa sonraki sync yeni hareketi opening'e yutar
      // (bakiye değişmez görünür).
      await syncBalance(walletId);

      final addResult = await transactionsRepository.addTransaction(tx);
      final added = addResult.fold(
        (failure) {
          debugPrint(
              'recordCashMovement: işlem yazılamadı: ${failure.message}');
          return false;
        },
        (_) => true,
      );
      if (!added) return false;
      return await syncBalance(walletId);
    } catch (e) {
      debugPrint('recordCashMovement başarısız: $e');
      return false;
    }
  }

  /// Bakiyeyi işlemlerden yeniden hesaplar; cüzdan bakiyesinin TEK yazım yolu.
  /// `balance = openingBalance + Σ signed(tüm işlemler)`.
  /// Eski cüzdanlarda `openingBalance` null ise mevcut bakiyeyi koruyacak
  /// şekilde (balance - Σtx) geri doldurulur.
  /// Başarı ya da no-op'ta `true`, herhangi bir hata bacağında `false` döner.
  Future<bool> syncBalance(String walletId) async {
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
            final txSum = txs.fold<double>(
              0.0,
              (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
            );

            final opening = wallet.openingBalance ?? (wallet.balance - txSum);
            final newBalance = opening + txSum;

            // Tutarlıysa hiç yazma (yaygın durum; gereksiz emit/yazma döngüsünü önler).
            if (wallet.openingBalance != null &&
                (wallet.balance - newBalance).abs() < 0.001) {
              return true;
            }

            // Eşzamanlı metrik güncellemelerini (debt/credit/investment) ezmemek için
            // yazmadan hemen önce güncel cüzdanı tekrar oku ve yalnız bakiye alanlarını
            // taze kayda uygula.
            final freshResult = await walletRepository.getWalletById(walletId);
            return freshResult.fold(
              (failure) async {
                debugPrint(
                    'syncBalance: taze cüzdan okunamadı: ${failure.message}');
                return false;
              },
              (fresh) async {
                final target = fresh ?? wallet;
                final writeResult = await walletRepository.updateWallet(
                  target.copyWith(openingBalance: opening, balance: newBalance),
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

  Future<void> syncDebt(String walletId) async {
    final result = await walletRepository.getWalletById(walletId);
    await result.fold(
      (failure) async => debugPrint('WalletMetricsService: ${failure.message}'),
      (wallet) async {
        if (wallet == null) return;

        final debtsResult = await debtRepository.getDebtsByWalletId(walletId);
        await debtsResult.fold(
          (failure) async =>
              debugPrint('WalletMetricsService: ${failure.message}'),
          (debts) async {
            final totalDebt = debts
                .where((debt) => !debt.isPaid)
                .fold<double>(0.0, (sum, debt) => sum + debt.remainingAmount);

            if ((wallet.debt - totalDebt).abs() >= 0.001) {
              await walletRepository
                  .updateWallet(wallet.copyWith(debt: totalDebt));
            }
          },
        );
      },
    );
  }

  Future<void> syncCredit(String walletId) async {
    final result = await walletRepository.getWalletById(walletId);
    await result.fold(
      (failure) async => debugPrint('WalletMetricsService: ${failure.message}'),
      (wallet) async {
        if (wallet == null) return;

        final receivablesResult =
            await receivableRepository.getReceivablesByWalletId(walletId);

        await receivablesResult.fold(
          (failure) async =>
              debugPrint('WalletMetricsService: ${failure.message}'),
          (receivables) async {
            final totalCredit = receivables
                .where((r) => !r.isPaid)
                .fold<double>(0.0, (sum, r) => sum + r.amount);

            if ((wallet.credit - totalCredit).abs() >= 0.001) {
              await walletRepository
                  .updateWallet(wallet.copyWith(credit: totalCredit));
            }
          },
        );
      },
    );
  }

  Future<void> syncInvestment(String walletId) async {
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
          (investments) => investments.fold<double>(
            0.0,
            (sum, item) => sum + item.currentValue,
          ),
        );

        if ((wallet.investment - totalInvestment).abs() >= 0.001) {
          await walletRepository
              .updateWallet(wallet.copyWith(investment: totalInvestment));
        }
      },
    );
  }

  /// Cüzdan silinirken o cüzdana bağlı tüm kayıtları (işlem/borç/alacak/yatırım)
  /// temizler; yetim veri kalmasını önler.
  Future<void> purgeWalletData(String walletId, String userId) async {
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
