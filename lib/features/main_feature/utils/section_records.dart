import 'dart:async';

import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/investments/data/datasource/goal_local_datasource.dart';
import 'package:cunehat/features/investments/data/models/goal_model.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:hive/hive.dart';

/// Birikim ve Borç bölümlerinin KAYDI var mı — doğrudan kutulardan.
///
/// `SectionVisibility` "kaydı olan bölüm açıktır ve kapatılamaz" der; bu sınıf
/// o sorunun cevabıdır. Bloc'lara sorulmaz: küpte yalnız GÖRÜNEN sayfa mount
/// edilir (`CubeFace` gizli yüzü ağaçtan düşürür), yani kapalı bir bölümün
/// bloc'u hiç yüklenmez ve ona sorulan soru hep "yok" döner. Cihaz özeti
/// (`currentDataSummary`) de kullanılmaz: bütün defteri tarar, oysa buradaki
/// soru kutunun boş olup olmadığıdır.
///
/// Kutular açılışta açılır (`AppInitialization`); açık değilse "kayıt yok"
/// sayılır.
class SectionRecords {
  SectionRecords([HiveInterface? hive]) : _hive = hive ?? Hive;

  final HiveInterface _hive;

  static const String investmentsBox = 'investments_box';
  static const String debtsBox = 'debts';
  static const String receivablesBox = 'receivables';
  static const String walletsBox = 'wallets';
  static const String transactionsBox = 'transactions';

  /// Varlık, nakit kasası ya da hedef.
  bool get savingsHasRecords =>
      _notEmpty<InvestmentModel>(investmentsBox) ||
      _notEmpty<GoalModel>(GoalLocalDataSource.boxName);

  /// Borç, alacak ya da kredi kartı (kartlar Borç bölümünde yaşar).
  bool get debtHasRecords =>
      _notEmpty<DebtModel>(debtsBox) ||
      _notEmpty<ReceivableModel>(receivablesBox) ||
      _hasCard;

  /// Defterdeki toplam kayıt sayısı (bütün cüzdanlar).
  ///
  /// Kutu henüz açılmadıysa 0: defter ekranı bir kez yüklendikten sonra açık
  /// kalır, yani kayıt yazılan her yerde gerçek sayıdır. Eşzamanlıdır ve
  /// kayıtları OKUMAZ (yalnız anahtar sayısı) — her kayıtta çağrılabilir.
  int get transactionCount => _hive.isBoxOpen(transactionsBox)
      ? _hive.box<TransactionModel>(transactionsBox).length
      : 0;

  bool _notEmpty<T>(String name) =>
      _hive.isBoxOpen(name) && _hive.box<T>(name).isNotEmpty;

  bool get _hasCard =>
      _hive.isBoxOpen(walletsBox) &&
      _hive
          .box<WalletModel>(walletsBox)
          .values
          .any((w) => w.creditCard != null);

  /// İlgili kutulardan biri değişti. Dinleyen [savingsHasRecords] /
  /// [debtHasRecords] değerlerini yeniden okur.
  ///
  /// Kayıt nereden yazılırsa yazılsın yakalanır: kendi formu, yedek geri
  /// yükleme, ekstre bağlama akışı ("birikim alımı", "kredi girişi").
  Stream<void> get changes {
    late final StreamController<void> controller;
    final subscriptions = <StreamSubscription<BoxEvent>>[];
    controller = StreamController<void>.broadcast(
      onListen: () {
        void watch<T>(String name) {
          if (!_hive.isBoxOpen(name)) return;
          subscriptions.add(
            _hive.box<T>(name).watch().listen((_) {
              if (!controller.isClosed) controller.add(null);
            }),
          );
        }

        watch<InvestmentModel>(investmentsBox);
        watch<GoalModel>(GoalLocalDataSource.boxName);
        watch<DebtModel>(debtsBox);
        watch<ReceivableModel>(receivablesBox);
        watch<WalletModel>(walletsBox);
      },
      onCancel: () async {
        for (final s in subscriptions) {
          await s.cancel();
        }
        subscriptions.clear();
      },
    );
    return controller.stream;
  }
}
