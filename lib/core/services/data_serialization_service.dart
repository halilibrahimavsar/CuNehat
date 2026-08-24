import 'dart:convert';

import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/backup_summary.dart';
import 'package:cunehat/core/services/reminder_sync_service.dart';
import 'package:cunehat/features/budgets/data/models/budget_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/core/services/receipt_storage_service.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/category_local_datasource.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:cunehat/features/investments/data/datasource/goal_local_datasource.dart';
import 'package:cunehat/features/investments/data/models/goal_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/recurring_transactions/data/models/recurring_transaction_model.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

enum DataRestoreStatus {
  success,
  invalidFormat,

  /// Dosya sağlam ama şema sürümü bu sürümle eşleşmiyor. `invalidFormat`'tan
  /// ayrı: kullanıcıya "yedek bozuk" demek yalan olurdu.
  versionMismatch,
  writeFailure,
}

class DataRestoreResult {
  final DataRestoreStatus status;
  final Object? error;

  /// Yalnız [DataRestoreStatus.versionMismatch] durumunda dolu: dosyadan
  /// okunan sürüm (int olmayabilir — bozuk/eski dosyada ne varsa).
  final Object? foundVersion;

  const DataRestoreResult._(this.status, [this.error, this.foundVersion]);

  const DataRestoreResult.success() : this._(DataRestoreStatus.success);
  const DataRestoreResult.invalidFormat([Object? error])
      : this._(DataRestoreStatus.invalidFormat, error);
  const DataRestoreResult.versionMismatch(Object? foundVersion)
      : this._(DataRestoreStatus.versionMismatch, null, foundVersion);
  const DataRestoreResult.writeFailure([Object? error])
      : this._(DataRestoreStatus.writeFailure, error);

  bool get isSuccess => status == DataRestoreStatus.success;
}

class _ParsedBackup {
  final List<WalletModel> wallets;
  final List<TransactionModel> transactions;
  final List<InvestmentModel> investments;
  final List<DebtModel> debts;
  final List<ReceivableModel> receivables;
  final List<BudgetModel> budgets;
  final List<RecurringTransactionModel> recurringTransactions;
  final Map<String, Map> users;
  final List<CategoryModel> categories;
  final List<GoalModel> goals;

  /// Yedeğin alındığı an (`timestamp`). Önizleme bunu gösterir; bozuksa null.
  final DateTime? timestamp;

  const _ParsedBackup({
    required this.wallets,
    required this.transactions,
    required this.investments,
    required this.debts,
    required this.receivables,
    required this.budgets,
    required this.recurringTransactions,
    required this.users,
    required this.categories,
    required this.goals,
    required this.timestamp,
  });
}

@lazySingleton
class DataSerializationService {
  /// Yayın öncesi politika: geriye uyumluluk YOK. Restore sürümü birebir
  /// eşleşmeyen yedeği reddeder; şema değişirse sürümü artır — eski yedek
  /// desteklenmez, açıkça hata verir.
  ///
  /// v2 (2026-07-20): işlemlere `receiptFileName` alanı eklendi (fiş/foto eki).
  /// Görsel binary'si yedeğe GİRMEZ — yalnız dosya adı taşınır.
  ///
  /// v3 (2026-07-28): düzenli işlem şablonlarına `anchorDay` eklendi (ayın
  /// kaçında tekrarlayacağı). Kenetlenmiş vade tarihinden geri türetilemez.
  ///
  /// v4 (2026-07-29): defter tarihlemesi + kategori kimliği.
  /// - Alacaklara `createdAt`: silmede ters kayıt bu tarihe yazılır; `dueDate`
  ///   (beklenen tahsilat) bunun yerine geçemez.
  /// - Alacaklara `collectedAt` (nullable): tutar düzeltmesinin tahsilat bacağı
  ///   bu tarihe yazılır, yoksa iki bacak farklı dönemlere düşer.
  /// - Kategorilere `displayName` (nullable): `id` artık sabit opak anahtar,
  ///   yeniden adlandırma bu alandan geçer.
  ///
  /// v5 (2026-07-31): işlemlere `reference` (nullable) — bankanın ekstredeki
  /// kendi hareket numarası (Dekont/Fiş/İşlem No). İçe aktarımlar arası
  /// tekrar tespitinin KESİN anahtarı; gün+tutar+başlık üçlüsü hem kullanıcı
  /// düzenlemesiyle bozulabildiği hem de gerçek ekstrelerde çakışabildiği için
  /// tek başına yetmiyordu (bkz. `TransactionEntity.reference`).
  /// v6 (2026-08-06): borç hesabı ve ödeme kaydı.
  /// - Borçlara `calcMode`: toplam geri ödemenin hangi yöntemle hesaplandığı.
  ///   Eskiden `interestRate`'in değerinden tahmin ediliyordu; tahmin yanlış
  ///   olduğunda düzenleme, kaydın toplamını sessizce değiştiriyordu.
  /// - Ödemelere `id`: düzenleme/silme kalıcı kimlikle hedeflenir.
  /// - Ödemelere `overdueInterestPart`: ödemenin gecikme faizine sayılan
  ///   kısmı. Borcun kalanı yalnız faiz-dışı kısımla azalır.
  ///
  /// v7 (2026-08-12): kategori sistemi yeniden kuruldu.
  /// - Kategoriler artık SharedPreferences'ta değil kendi Hive kutusunda;
  ///   yedekte de ham prefs string'i değil GERÇEK BİR LİSTE olarak taşınırlar.
  /// - `id` kullanıcının verdiği ad değil UUID; ad ayrı `name` alanında.
  /// - `parentId` (nullable): iki seviyeli hiyerarşi.
  /// - `isDefault` kaldırıldı — varsayılan kategori kavramı yok.
  ///
  /// v8 (2026-08-24): yatırım kaydına `unbookedCost` (HiveField 15).
  /// - Uygulamaya girmeden ÖNCE alınmış varlık ("bu varlık zaten bende")
  ///   eklenirken maliyet cüzdandan düşülmez; düşülmeyen kısım burada durur.
  /// - Silme düzeltmesi yalnız deftere işlenmiş kısmı iade eder.
  ///
  /// v9 (2026-08-24): birikim hedefi kendi kaydı oldu (`goals` kutusu,
  /// typeId 16).
  /// - Yatırımdaki `targetAmount` (HiveField 11) ve `goalCategory` (13)
  ///   KALDIRILDI; yerine `goalId` (16) geldi.
  /// - Böylece gram altın + çeyrek altın + hisse TEK hedefin altında
  ///   toplanabiliyor; ilerleme üyelerin güncel değerlerinden hesaplanır.
  static const int schemaVersion = 9;

  final HiveInterface _hive;
  final ReceiptStorageService _receiptStorage;

  /// Bu servis "cihaz-yerel verinin tamamı"nın yaşam döngüsünü sahiplenir
  /// (Hive kutuları + kategori tercihleri + fiş görselleri). Planlanmış
  /// hatırlatmalar da o verinin türevi: kaydı silinen/değişen bir borç veya
  /// şablon için OS'ta planlı kalan bildirim, silinmiş verinin adını günler
  /// sonra kullanıcının kilit ekranına düşürür. Bu yüzden bildirim tarafı da
  /// buradan sürülür — silme/geri yükleme çağıranlarının unutabileceği bir
  /// adım olarak değil.
  final NotificationService _notifications;
  final ReminderSyncService _reminderSync;

  DataSerializationService(
    this._receiptStorage,
    this._notifications,
    this._reminderSync,
  ) : _hive = Hive;

  @visibleForTesting
  DataSerializationService.withHive(
    this._hive,
    this._receiptStorage,
    this._notifications,
    this._reminderSync,
  );

  /// Tüm yerel veriyi siler: tüm Hive kutuları (cüzdan/işlem/yatırım/borç/
  /// alacak/bütçe/tekrarlayan/kullanıcı) + yedeklenebilir kategori tercihleri.
  /// "Tüm veriyi sil" gizlilik özelliği içindir. GERİ ALINAMAZ; çağıran onay
  /// almalıdır. Boş yedeği geri yüklemekle aynı temizleme yolunu kullanır.
  Future<void> clearAllLocalData() async {
    await (await _hive.openBox<WalletModel>('wallets')).clear();
    await (await _hive.openBox<TransactionModel>('transactions')).clear();
    await (await _hive.openBox<InvestmentModel>('investments_box')).clear();
    await (await _hive.openBox<DebtModel>('debts')).clear();
    await (await _hive.openBox<ReceivableModel>('receivables')).clear();
    await (await _hive.openBox<BudgetModel>('budgets_box')).clear();
    await (await _hive
            .openBox<RecurringTransactionModel>('recurring_transactions_box'))
        .clear();
    await (await _hive.openBox<Map>('users')).clear();

    await (await _hive.openBox<CategoryModel>(CategoryLocalDataSource.boxName))
        .clear();
    await (await _hive.openBox<GoalModel>(GoalLocalDataSource.boxName)).clear();

    // İşlemlere iliştirilmiş fiş görselleri de cihaz-yerel; onları da temizle.
    await _receiptStorage.clearAll();

    // Planlanmış hatırlatmalar Hive'da değil OS'ta yaşar; kutuları boşaltmak
    // onları iptal ETMEZ. Aksi halde kullanıcı "tüm veriyi sil" dedikten sonra
    // ertesi sabah silinmiş borcunun başlığıyla bildirim alırdı.
    await _notifications.cancelAllNotifications();
  }

  Future<String> exportDataToJson() async {
    final walletBox = await _hive.openBox<WalletModel>('wallets');
    final transactionBox =
        await _hive.openBox<TransactionModel>('transactions');
    final investmentBox =
        await _hive.openBox<InvestmentModel>('investments_box');
    final debtBox = await _hive.openBox<DebtModel>('debts');
    final receivableBox = await _hive.openBox<ReceivableModel>('receivables');
    final budgetBox = await _hive.openBox<BudgetModel>('budgets_box');
    final recurringBox = await _hive
        .openBox<RecurringTransactionModel>('recurring_transactions_box');
    final userBox = await _hive.openBox<Map>('users');

    final users = <String, Map>{};
    for (final key in userBox.keys) {
      final value = userBox.get(key);
      if (value != null) {
        users[key.toString()] = Map<String, dynamic>.from(value);
      }
    }

    final categoryBox =
        await _hive.openBox<CategoryModel>(CategoryLocalDataSource.boxName);
    final goalBox = await _hive.openBox<GoalModel>(GoalLocalDataSource.boxName);

    return jsonEncode({
      'version': schemaVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'wallets': walletBox.values.map((w) => w.toJson()).toList(),
      'transactions': transactionBox.values.map((t) => t.toJson()).toList(),
      'investments': investmentBox.values.map((i) => i.toJson()).toList(),
      'debts': debtBox.values.map((d) => d.toJson()).toList(),
      'receivables': receivableBox.values.map((r) => r.toJson()).toList(),
      'budgets': budgetBox.values.map((b) => b.toJson()).toList(),
      'recurringTransactions':
          recurringBox.values.map((r) => r.toJson()).toList(),
      'users': users,
      'categories': categoryBox.values.map((c) => c.toJson()).toList(),
      'goals': goalBox.values.map((g) => g.toJson()).toList(),
    });
  }

  Future<DataRestoreResult> importDataFromJson(String jsonString) async {
    final _ParsedBackup parsedBackup;
    try {
      parsedBackup = _parseBackup(jsonString);
    } on BackupVersionMismatch catch (e) {
      debugPrint('DataSerializationService version mismatch: $e');
      return DataRestoreResult.versionMismatch(e.found);
    } catch (e, st) {
      debugPrint('DataSerializationService parse error: $e\n$st');
      return DataRestoreResult.invalidFormat(e);
    }

    final walletBox = await _hive.openBox<WalletModel>('wallets');
    final transactionBox =
        await _hive.openBox<TransactionModel>('transactions');
    final investmentBox =
        await _hive.openBox<InvestmentModel>('investments_box');
    final debtBox = await _hive.openBox<DebtModel>('debts');
    final receivableBox = await _hive.openBox<ReceivableModel>('receivables');
    final budgetBox = await _hive.openBox<BudgetModel>('budgets_box');
    final recurringBox = await _hive
        .openBox<RecurringTransactionModel>('recurring_transactions_box');
    final userBox = await _hive.openBox<Map>('users');

    final categoryBox =
        await _hive.openBox<CategoryModel>(CategoryLocalDataSource.boxName);
    final categorySnapshot = Map.of(categoryBox.toMap());

    final goalBox = await _hive.openBox<GoalModel>(GoalLocalDataSource.boxName);
    final goalSnapshot = Map.of(goalBox.toMap());

    final walletSnapshot = Map.of(walletBox.toMap());
    final transactionSnapshot = Map.of(transactionBox.toMap());
    final investmentSnapshot = Map.of(investmentBox.toMap());
    final debtSnapshot = Map.of(debtBox.toMap());
    final receivableSnapshot = Map.of(receivableBox.toMap());
    final budgetSnapshot = Map.of(budgetBox.toMap());
    final recurringSnapshot = Map.of(recurringBox.toMap());
    final userSnapshot = Map.of(userBox.toMap());

    try {
      await walletBox.clear();
      await transactionBox.clear();
      await investmentBox.clear();
      await debtBox.clear();
      await receivableBox.clear();
      await budgetBox.clear();
      await recurringBox.clear();
      await userBox.clear();

      for (final model in parsedBackup.wallets) {
        final id = model.id;
        if (id == null) throw StateError('Wallet id is missing');
        await walletBox.put(id, model);
      }
      for (final model in parsedBackup.transactions) {
        final id = model.id;
        if (id == null) throw StateError('Transaction id is missing');
        await transactionBox.put(id, model);
      }
      for (final model in parsedBackup.investments) {
        final id = model.id;
        if (id == null) throw StateError('Investment id is missing');
        await investmentBox.put(id, model);
      }
      for (final model in parsedBackup.debts) {
        final id = model.id;
        if (id == null) throw StateError('Debt id is missing');
        await debtBox.put(id, model);
      }
      for (final model in parsedBackup.receivables) {
        final id = model.id;
        if (id == null) throw StateError('Receivable id is missing');
        await receivableBox.put(id, model);
      }
      for (final model in parsedBackup.budgets) {
        await budgetBox.put(model.storageKey, model);
      }
      for (final model in parsedBackup.recurringTransactions) {
        await recurringBox.put(model.id, model);
      }
      for (final entry in parsedBackup.users.entries) {
        await userBox.put(entry.key, entry.value);
      }

      // Kategoriler tam değişim: yedekte olmayan bir kategori geri yükleme
      // sonrası kalırsa, ona bağlı olmayan işlemlerle birlikte hayalet kayıt
      // olur.
      await categoryBox.clear();
      for (final model in parsedBackup.categories) {
        await categoryBox.put(model.id, model);
      }

      // Hedefler de tam değişim: yedekte olmayan bir hedef kalırsa hiçbir
      // yatırımın bağlı olmadığı boş bir ilerleme çubuğu olurdu.
      await goalBox.clear();
      for (final model in parsedBackup.goals) {
        await goalBox.put(model.id, model);
      }

      // Yalnız başarıda yörünge temizliği: geri yüklenen veri fiş binary'si
      // taşımaz. Hâlâ atıfta bulunulan görseller korunur (aynı-cihaz geri
      // yüklemede kayıp olmaz); atıfsız kalanlar silinir. (Başarısızlıkta
      // rollback eski veriyi geri getirir, görseller de yerinde kalmalı.)
      final keepReceipts = <String>{
        for (final t in parsedBackup.transactions)
          if (t.receiptFileName != null) t.receiptFileName!,
      };
      await _receiptStorage.pruneExcept(keepReceipts);

      // Geri yükleme şablon ve borç kümesini komple değiştirir: eski kayıtların
      // kimliğinden türeyen bildirimler (ReminderIds.recurring/debt*) planlı
      // kalır, geri yüklenenler ise hiç kurulmaz. Önce OS'taki her şeyi düşür,
      // sonra ReminderSyncService yeni veriden baştan kursun — aksi halde
      // hatırlatmalar bir sonraki soğuk açılışa kadar yanlış kalıyordu.
      await _notifications.cancelAllNotifications();
      await _reminderSync.syncAll();

      return const DataRestoreResult.success();
    } catch (e, st) {
      debugPrint('DataSerializationService write error: $e\n$st');
      try {
        await _rollback(walletBox, walletSnapshot);
        await _rollback(transactionBox, transactionSnapshot);
        await _rollback(investmentBox, investmentSnapshot);
        await _rollback(debtBox, debtSnapshot);
        await _rollback(receivableBox, receivableSnapshot);
        await _rollback(budgetBox, budgetSnapshot);
        await _rollback(recurringBox, recurringSnapshot);
        await _rollback(userBox, userSnapshot);
        await _rollback(categoryBox, categorySnapshot);
        await _rollback(goalBox, goalSnapshot);
      } catch (rollbackError, rollbackSt) {
        debugPrint(
          'DataSerializationService rollback FAILED: '
          '$rollbackError\n$rollbackSt',
        );
      }
      return DataRestoreResult.writeFailure(e);
    }
  }

  /// Yedeği YAZMADAN okur ve özetler. Önizleme ekranının tek veri kaynağı.
  ///
  /// [importDataFromJson] ile aynı ayrıştırıcıyı (`_parseBackup`) kullanır —
  /// yani önizlemenin "geri yüklenebilir" demesi ile geri yüklemenin gerçekten
  /// çalışması aynı koda dayanır. Ayrı bir "hafif ayrıştırıcı" yazmak, tam da
  /// önizlemenin engellemesi gereken sürprizi geri getirirdi.
  BackupInspection inspectBackup(String jsonString) {
    try {
      final parsed = _parseBackup(jsonString);
      return BackupInspection.ok(
        _summarize(
          wallets: parsed.wallets,
          transactions: parsed.transactions,
          investmentCount: parsed.investments.length,
          debtCount: parsed.debts.length,
          receivableCount: parsed.receivables.length,
          budgetCount: parsed.budgets.length,
          recurringCount: parsed.recurringTransactions.length,
          categoryCount: parsed.categories.length,
          goalCount: parsed.goals.length,
          createdAt: parsed.timestamp,
        ),
        schemaVersion,
      );
    } on BackupVersionMismatch catch (e) {
      return BackupInspection.versionMismatch(e.found, schemaVersion);
    } catch (e, st) {
      debugPrint('DataSerializationService inspect error: $e\n$st');
      return BackupInspection.corrupt(e, schemaVersion);
    }
  }

  /// Cihazdaki mevcut verinin aynı biçimdeki özeti. Önizlemedeki fark paneli
  /// ("geri yüklersen 23 işlem kaybolur") ve otomatik yedeğin boş-veri kapısı
  /// bunu kullanır.
  Future<BackupSummary> currentDataSummary() async {
    final walletBox = await _hive.openBox<WalletModel>('wallets');
    final transactionBox =
        await _hive.openBox<TransactionModel>('transactions');
    final investmentBox =
        await _hive.openBox<InvestmentModel>('investments_box');
    final debtBox = await _hive.openBox<DebtModel>('debts');
    final receivableBox = await _hive.openBox<ReceivableModel>('receivables');
    final budgetBox = await _hive.openBox<BudgetModel>('budgets_box');
    final recurringBox = await _hive
        .openBox<RecurringTransactionModel>('recurring_transactions_box');

    final categoryBox =
        await _hive.openBox<CategoryModel>(CategoryLocalDataSource.boxName);
    final goalBox = await _hive.openBox<GoalModel>(GoalLocalDataSource.boxName);

    return _summarize(
      wallets: walletBox.values.toList(),
      transactions: transactionBox.values.toList(),
      investmentCount: investmentBox.length,
      debtCount: debtBox.length,
      receivableCount: receivableBox.length,
      budgetCount: budgetBox.length,
      recurringCount: recurringBox.length,
      categoryCount: categoryBox.length,
      goalCount: goalBox.length,
      createdAt: null,
    );
  }

  BackupSummary _summarize({
    required List<WalletModel> wallets,
    required List<TransactionModel> transactions,
    required int investmentCount,
    required int debtCount,
    required int receivableCount,
    required int budgetCount,
    required int recurringCount,
    required int categoryCount,
    required int goalCount,
    required DateTime? createdAt,
  }) {
    DateTime? first;
    DateTime? last;
    var income = 0.0;
    var expense = 0.0;
    var withReceipt = 0;

    for (final t in transactions) {
      if (first == null || t.date.isBefore(first)) first = t.date;
      if (last == null || t.date.isAfter(last)) last = t.date;
      if (t.type == TransactionTypeModel.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
      if (t.receiptFileName != null) withReceipt++;
    }

    return BackupSummary(
      schemaVersion: schemaVersion,
      createdAt: createdAt,
      walletCount: wallets.length,
      transactionCount: transactions.length,
      investmentCount: investmentCount,
      debtCount: debtCount,
      receivableCount: receivableCount,
      budgetCount: budgetCount,
      recurringCount: recurringCount,
      categoryCount: categoryCount,
      goalCount: goalCount,
      wallets: [
        for (final w in wallets)
          BackupWalletSummary(
            name: w.name,
            currency: w.currency,
            balance: w.balance,
          ),
      ],
      firstTransactionDate: first,
      lastTransactionDate: last,
      totalIncome: income,
      totalExpense: expense,
      transactionsWithReceipt: withReceipt,
    );
  }

  _ParsedBackup _parseBackup(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup root must be a JSON object');
    }

    // Sürüm kapısı: farklı şema sessizce yanlış yorumlanmasın, açıkça reddet.
    // Tipli istisna: `FormatException` ile aynı sepete düşerse çağıran
    // "bozuk dosya" der ve kullanıcıya yalan söyler.
    final version = decoded['version'];
    if (version != schemaVersion) {
      throw BackupVersionMismatch(version, schemaVersion);
    }

    final users = <String, Map>{};
    final usersMap = decoded['users'] as Map<String, dynamic>? ?? {};
    for (final entry in usersMap.entries) {
      users[entry.key] = Map<dynamic, dynamic>.from(entry.value as Map);
    }

    // v7'den itibaren kategoriler gerçek bir liste; öncesinde ham prefs
    // string'lerinin haritasıydı. Sürüm kapısı eski yedeği zaten reddettiği
    // için burada tek biçim tanınır.
    final categories = _list(decoded, 'categories')
        .map((c) => CategoryModel.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();

    final goals = _list(decoded, 'goals')
        .map((g) => GoalModel.fromJson(Map<String, dynamic>.from(g as Map)))
        .toList();

    return _ParsedBackup(
      wallets: _list(decoded, 'wallets').map((w) {
        final data = Map<String, dynamic>.from(w as Map);
        return WalletModel.fromJson(data['id'] as String, data);
      }).toList(),
      transactions: _list(decoded, 'transactions').map((t) {
        final data = Map<String, dynamic>.from(t as Map);
        return TransactionModel.fromJson(data['id'] as String, data);
      }).toList(),
      investments: _list(decoded, 'investments').map((i) {
        final data = Map<String, dynamic>.from(i as Map);
        return InvestmentModel.fromJson(data['id'] as String, data);
      }).toList(),
      debts: _list(decoded, 'debts')
          .map((d) => DebtModel.fromJson(Map<String, dynamic>.from(d as Map)))
          .toList(),
      receivables: _list(decoded, 'receivables')
          .map((r) =>
              ReceivableModel.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList(),
      budgets: _list(decoded, 'budgets')
          .map((b) => BudgetModel.fromJson(Map<String, dynamic>.from(b as Map)))
          .toList(),
      recurringTransactions: _list(decoded, 'recurringTransactions')
          .map((r) => RecurringTransactionModel.fromJson(
              Map<String, dynamic>.from(r as Map)))
          .toList(),
      users: users,
      categories: categories,
      goals: goals,
      timestamp: DateTime.tryParse(decoded['timestamp'] as String? ?? ''),
    );
  }

  List<dynamic> _list(Map<String, dynamic> data, String key) {
    return data[key] as List<dynamic>? ?? const [];
  }

  Future<void> _rollback(Box box, Map snapshot) async {
    await box.clear();
    await box.putAll(snapshot);
  }
}
