// Hive'ın `HiveImpl`'i genel API'de dışa vurulmuyor ama testin yalıtımı buna
// bağlı: her örneğin KENDİ adapter kaydı var, böylece aynı dizini önce ESKİ
// sonra GÜNCEL kayıtla açabiliyoruz. Alternatif `Hive.resetAdapters()` yanlış
// olurdu — o, DateTime/BigInt iç adapter'larını da siler ve `HiveImpl` onları
// geri yüklemez, yani tarih alanı olan her model bozulur.
// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:cunehat/config/initialization/app_initialization.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/recurring_transactions/data/models/recurring_transaction_model.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/wallet/data/models/credit_card_info_model.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive/src/hive_impl.dart';

/// **Gerçek diskte yükseltme testi: eski biçimli kutu, güncel kodla açılır.**
///
/// `legacy_safe_adapters_test.dart` `read()`i sahte bir `BinaryReader` ile
/// çağırıyor — doğru ama yetersiz: `openBox`'ın kendi kare ayrıştırması,
/// `numOfFields` işlemesi ve **hangi adapter'ın gerçekten kayıtlı olduğu** o
/// yoldan geçmiyor. Burada dosya gerçekten ESKİ sürümün yazacağı baytlarla
/// diske yazılıyor ve `AppInitialization.typeAdapters` ile geri açılıyor.
///
/// Ölçtüğü senaryo, testerların yaşayacağının ta kendisi: `v1.0.0+4` kurulu
/// bir cihaz güncellemeyi alıyor ve mevcut kutular açılmak zorunda. `openBox`
/// kutunun BÜTÜN karelerini okuduğu için tek bir eski kayıt kutuyu tamamen
/// açılamaz hâle getirir — uygulama hiç açılmaz, kullanıcı siler, sayaç sıfırlanır.
void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cunehat_legacy_box');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  /// Eski sürümü taklit eden yazıcılar ÖNCE kaydedilir; kalan her şey (enum ve
  /// `Color` adapter'ları) üretimdeki listeden gelir. `registerTypeAdapters`
  /// kayıtlı typeId'leri atladığı için model typeId'leri eski yazıcıda kalır.
  Future<HiveImpl> legacyHive(List<AdapterRegistration> writers) async {
    final hive = HiveImpl()..init(dir.path);
    for (final w in writers) {
      w.registerOn(hive);
    }
    AppInitialization.registerTypeAdapters(hive);
    return hive;
  }

  /// Güncel uygulamanın açılışta kurduğu kaydın birebir aynısı.
  HiveImpl currentHive() {
    final hive = HiveImpl()..init(dir.path);
    AppInitialization.registerTypeAdapters(hive);
    return hive;
  }

  /// Eski biçimde yaz → kapat → güncel kayıtla aç → tek kaydı döndür.
  Future<T> upgrade<T>(
    String boxName,
    T value,
    List<AdapterRegistration> writers,
  ) async {
    final legacy = await legacyHive(writers);
    final box = await legacy.openBox<T>(boxName);
    await box.put('k', value);
    await legacy.close();

    final current = currentHive();
    final reopened = await current.openBox<T>(boxName);
    final read = reopened.get('k') as T;
    await current.close();
    return read;
  }

  test('cüzdan: v10 öncesi 14 alanlı kayıt açılır, kürasyonsuz gelir',
      () async {
    // +4 → +5 yolunun TA KENDİSİ: 13 testerın cüzdanları bu biçimde duruyor.
    final back = await upgrade(
      'wallets',
      WalletModel(
        id: 'w1',
        userId: 'u',
        name: 'Nakit',
        balance: 1500.0,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: '0xFF4CAF50',
        iconName: 'account_balance_wallet',
        createdAt: DateTime(2026, 8, 28),
        isActive: true,
        sortOrder: 0,
        openingBalance: 1000.0,
        currency: 'TRY',
        categoryIds: const ['bu-alan-eski-kayda-YAZILMAZ'],
      ),
      [AdapterRegistration.of(_LegacyWalletWriter())],
    );

    expect(back.name, 'Nakit');
    expect(back.balance, 1500.0);
    expect(back.currency, 'TRY');
    expect(
      back.categoryIds,
      isNull,
      reason: 'Alan 14 eski kayıtta YOK; `null` = kürasyon yapılmamış = tüm '
          'kategoriler görünür. `[]` gelseydi testerın cüzdanında hiçbir '
          'kategori görünmezdi.',
    );
  });

  test('cüzdan: v12 öncesi 15 alanlı kayıt açılır, DÜZ cüzdan gelir', () async {
    // Faz 3'ün yükseltme yolu: 24 Eyl 2026 itibarıyla testerların cüzdanları
    // alan 14'e (categoryIds) kadar yazılı; alan 15 (kredi kartı) yok.
    final back = await upgrade(
      'wallets',
      WalletModel(
        id: 'w1',
        userId: 'u',
        name: 'Bonus',
        balance: -2500.0,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: '0xFF4CAF50',
        iconName: 'credit_card',
        createdAt: DateTime(2026, 9, 1),
        isActive: true,
        sortOrder: 0,
        openingBalance: 0,
        currency: 'TRY',
        categoryIds: const ['cat-a'],
      ),
      [AdapterRegistration.of(_LegacyV11WalletWriter())],
    );

    expect(back.name, 'Bonus');
    expect(back.categoryIds, ['cat-a'], reason: 'alan 14 korunur');
    expect(back.creditCard, isNull, reason: 'alan 15 eski kayıtta YOK');
  });

  test('kart cüzdanı gerçek kutuda yazılıp okunur (iç içe typeId 17/18)',
      () async {
    final card = CreditCardInfoModel(
      bankName: 'Garanti BBVA',
      last4: '5690',
      limit: 50000,
      closingDay: 31,
      dueDay: 10,
      paymentWalletId: 'w-bank',
      lastStatement: CardStatementModel(
        closingDate: DateTime(2026, 8, 31),
        dueDate: DateTime(2026, 9, 10),
        statementBalance: 12345.67,
        minimumPayment: null,
        source: 'manual',
        recordedAt: DateTime(2026, 9, 1, 9),
      ),
    );
    final hive = currentHive();
    final box = await hive.openBox<WalletModel>('wallets');
    await box.put(
      'k',
      WalletModel(
        id: 'card',
        userId: 'u',
        name: 'Bonus',
        balance: -12345.67,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: '0xFF4CAF50',
        iconName: 'credit_card',
        createdAt: DateTime(2026, 9, 1),
        openingBalance: -12345.67,
        creditCard: card,
      ),
    );
    await hive.close();

    final again = currentHive();
    final back = (await again.openBox<WalletModel>('wallets')).get('k')!;
    await again.close();

    expect(back.creditCard?.toEntity(), card.toEntity());
  });

  test('kart: v15 biçimli (7 alanlı) kart bilgisi açılır, yeni alanlar null',
      () async {
    // 12 Eki 2026 öncesinde yazılmış kart cüzdanı: alan 7–9 (gün farkı,
    // faiz oranları) karede YOK. İç içe kayıt okunamazsa cüzdan kutusu
    // açılmaz — uygulama açılmaz.
    final back = await upgrade(
      'wallets',
      WalletModel(
        id: 'card',
        userId: 'u',
        name: 'Bonus',
        balance: -3700.0,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: '0xFF4CAF50',
        iconName: 'credit_card',
        createdAt: DateTime(2026, 9, 1),
        openingBalance: -3700.0,
        creditCard: const CreditCardInfoModel(
          bankName: 'QNB',
          last4: '4321',
          limit: 20000,
          closingDay: 25,
          dueDay: 5,
          paymentWalletId: 'w1',
          // Eski yazıcı bunları YAZMAZ: geri okunursa yazıcı hatalıdır.
          dueOffsetDays: 99,
          monthlyInterestRate: 99,
          lateInterestRate: 99,
        ),
      ),
      [AdapterRegistration.of(_V15CardInfoWriter())],
    );

    final card = back.creditCard!;
    expect(card.bankName, 'QNB');
    expect(card.last4, '4321');
    expect(card.limit, 20000);
    expect(card.closingDay, 25);
    expect(card.dueDay, 5);
    expect(card.paymentWalletId, 'w1');
    expect(card.dueOffsetDays, isNull, reason: 'alan 7 eski kayıtta YOK');
    expect(card.monthlyInterestRate, isNull, reason: 'alan 8 YOK');
    expect(card.lateInterestRate, isNull, reason: 'alan 9 YOK');
  });

  test('yatırım: v15 biçimli (isPrimary yok) kasa açılır, ana kasa DEĞİL',
      () async {
    final back = await upgrade(
      'investments_box',
      InvestmentModel(
        id: 'pot',
        userId: 'u',
        walletId: 'w1',
        name: 'Acil durum',
        amount: 1500.0,
        currentValue: 1500.0,
        type: InvestmentType.cash,
        color: const Color(0xFF26A69A),
        dateAdded: DateTime(2026, 9, 1),
        goalId: 'g1',
        unbookedCost: 250.0,
        // Eski yazıcı bunu YAZMAZ.
        isPrimary: true,
      ),
      [AdapterRegistration.of(_V15InvestmentWriter())],
    );

    expect(back.isPrimary, isFalse, reason: 'alan 17 eski kayıtta YOK');
    expect(back.name, 'Acil durum');
    expect(back.amount, 1500.0);
    expect(back.unbookedCost, 250.0);
    expect(back.goalId, 'g1');
    expect(back.type, InvestmentType.cash);
  });

  test('işlem: v11 öncesi 11 alanlı kayıt açılır, yeni alanlar null gelir',
      () async {
    // 23 Eyl 2026: testerların defteri bu biçimde duruyor. Üç yeni alan
    // (kuplaj sahibi, benimseme izi, köken) nullable; üretilen adapter
    // `fields[11] as String?` okur — eski kare onları taşımaz.
    final back = await upgrade(
      'transactions',
      TransactionModel(
        id: 't1',
        userId: 'u',
        walletId: 'w1',
        title: 'BIM MAGAZALAR',
        tag: 'cat-market',
        amount: 913.15,
        date: DateTime(2026, 9, 5),
        type: TransactionTypeModel.expense,
        isSystem: false,
        reference: 'DK-77',
        linkedRecordId: 'bu-alan-eski-kayda-YAZILMAZ',
        adoptedFromTag: 'bu-da',
        origin: 'bu-da',
      ),
      [AdapterRegistration.of(_LegacyTransactionWriter())],
    );

    expect(back.title, 'BIM MAGAZALAR');
    expect(back.amount, 913.15);
    expect(back.reference, 'DK-77');
    expect(back.linkedRecordId, isNull);
    expect(back.adoptedFromTag, isNull);
    expect(back.origin, isNull);
    expect(back.isAdopted, isFalse);
  });

  test('yatırım: unbookedCost/goalId olmayan kayıt açılır', () async {
    final back = await upgrade(
      'investments_box',
      InvestmentModel(
        id: 'i1',
        userId: 'u',
        walletId: 'w',
        name: 'Gram Altın',
        amount: 5000.0,
        currentValue: 5400.0,
        type: InvestmentType.gold,
        color: const Color(0xFFFFC107),
        dateAdded: DateTime(2026, 8, 1),
        symbol: 'gram',
        returnRate: 8.0,
        quantity: 2.0,
        currency: 'TRY',
        unbookedCost: 999.0,
      ),
      [AdapterRegistration.of(_LegacyInvestmentWriter())],
    );

    expect(back.name, 'Gram Altın');
    expect(back.quantity, 2.0);
    expect(back.unbookedCost, 0, reason: 'Eksik alan 0\'a düşmeli.');
    expect(back.goalId, isNull);
  });

  test('borç + ödeme: v6 öncesi kayıt açılır, türetilmiş varsayılanlar gelir',
      () async {
    final back = await upgrade(
      'debts',
      DebtModel(
        id: 'd1',
        userId: 'u',
        walletId: 'w',
        title: 'Kredi',
        counterparty: 'YAZILMAZ',
        type: DebtType.bankLoan,
        calcMode: DebtCalcMode.amortized,
        principalAmount: 10000.0,
        interestRate: 2.5,
        termMonths: 12,
        overdueInterestRate: 9.9,
        startDate: DateTime(2026, 1, 1),
        dueDate: DateTime(2027, 1, 1),
        payments: [
          PaymentModel(
            id: 'YAZILMAZ',
            date: DateTime(2026, 2, 1),
            amount: 500.0,
            overdueInterestPart: 42.0,
            notes: 'ilk',
          ),
        ],
        isPaid: false,
        notes: 'not',
        expectedTotalAmount: 13000.0,
        principalToWallet: false,
      ),
      [
        AdapterRegistration.of(_LegacyDebtWriter()),
        AdapterRegistration.of(_LegacyPaymentWriter()),
      ],
    );

    expect(back.title, 'Kredi');
    expect(back.principalAmount, 10000.0);
    expect(back.counterparty, '');
    expect(back.overdueInterestRate, 0);
    expect(
      back.calcMode,
      DebtCalcMode.none,
      reason: 'Mod tahmin edilseydi borcun büyüklüğü sessizce değişirdi.',
    );
    expect(
      back.expectedTotalAmount,
      10000.0,
      reason: 'Anaparaya düşer — faizi uydurmak yerine bilinen tek sayı.',
    );
    expect(back.principalToWallet, isTrue);

    final payment = back.payments.single;
    expect(payment.amount, 500.0);
    expect(payment.overdueInterestPart, 0);
    expect(payment.id, isNotEmpty);
    expect(
      payment.id,
      isNot('YAZILMAZ'),
      reason: 'Eski kayıtta id yok; tarih+tutardan DETERMİNİSTİK üretilir.',
    );
  });

  test('alacak: createdAt olmayan kayıt açılır, vadeye düşer', () async {
    final due = DateTime(2026, 6, 20);
    final back = await upgrade(
      'receivables',
      ReceivableModel(
        id: 'r1',
        userId: 'u',
        walletId: 'w',
        debtorName: 'Ali',
        amount: 500.0,
        dueDate: due,
        createdAt: DateTime(2026, 5, 1),
        isPaid: false,
        notes: 'not',
      ),
      [AdapterRegistration.of(_LegacyReceivableWriter())],
    );

    expect(back.debtorName, 'Ali');
    expect(back.amount, 500.0);
    expect(back.createdAt, due, reason: 'Kayıttaki tek tarih vadedir.');
    expect(back.collectedAt, isNull);
  });

  test('düzenli işlem: anchorDay olmayan kayıt açılır, vadenin günü olur',
      () async {
    final back = await upgrade(
      'recurring_transactions_box',
      RecurringTransactionModel(
        id: 'rt1',
        userId: 'u',
        walletId: 'w',
        title: 'Kira',
        tag: 'bills.rent',
        amount: 7500.0,
        type: TransactionTypeModel.expense,
        frequency: RecurringFrequency.monthly,
        nextExecutionDate: DateTime(2026, 3, 25),
        anchorDay: 99,
        isActive: true,
      ),
      [AdapterRegistration.of(_LegacyRecurringWriter())],
    );

    expect(back.title, 'Kira');
    expect(back.amount, 7500.0);
    expect(back.anchorDay, 25, reason: 'startingOn fabrikasıyla aynı kural.');
  });

  test('eski kayıtlı 5 kutu, uygulamanın yaptığı gibi PARALEL açılır',
      () async {
    // Tek tek geçip birlikte kırılan bir kombinasyon olmadığını ölçer:
    // `_initializeHive` kutuları `Future.wait` ile paralel açıyor, yani ilk
    // hata diğerlerini de düşürür.
    final legacy = await legacyHive([
      AdapterRegistration.of(_LegacyWalletWriter()),
      AdapterRegistration.of(_LegacyInvestmentWriter()),
      AdapterRegistration.of(_LegacyDebtWriter()),
      AdapterRegistration.of(_LegacyPaymentWriter()),
      AdapterRegistration.of(_LegacyReceivableWriter()),
      AdapterRegistration.of(_LegacyRecurringWriter()),
    ]);

    await (await legacy.openBox<WalletModel>('wallets')).put(
      'w',
      WalletModel(
        id: 'w1',
        userId: 'u',
        name: 'Nakit',
        balance: 1,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: '0xFF000000',
        iconName: 'wallet',
        createdAt: DateTime(2026, 8, 28),
        openingBalance: 1,
      ),
    );
    await (await legacy.openBox<InvestmentModel>('investments_box')).put(
      'i',
      InvestmentModel(
        id: 'i1',
        userId: 'u',
        walletId: 'w1',
        name: 'Altın',
        amount: 100,
        currentValue: 110,
        type: InvestmentType.gold,
        color: const Color(0xFFFFC107),
        dateAdded: DateTime(2026, 8, 1),
        unbookedCost: 0,
      ),
    );
    await (await legacy.openBox<DebtModel>('debts')).put(
      'd',
      DebtModel(
        id: 'd1',
        userId: 'u',
        walletId: 'w1',
        title: 'Kredi',
        counterparty: 'Banka',
        type: DebtType.bankLoan,
        calcMode: DebtCalcMode.none,
        principalAmount: 100,
        interestRate: 0,
        termMonths: 1,
        overdueInterestRate: 0,
        startDate: DateTime(2026, 1, 1),
        payments: [
          PaymentModel(
            id: 'p1',
            date: DateTime(2026, 2, 1),
            amount: 10,
            overdueInterestPart: 0,
          ),
        ],
        isPaid: false,
        expectedTotalAmount: 100,
        principalToWallet: true,
      ),
    );
    await (await legacy.openBox<ReceivableModel>('receivables')).put(
      'r',
      ReceivableModel(
        id: 'r1',
        userId: 'u',
        walletId: 'w1',
        debtorName: 'Ali',
        amount: 5,
        dueDate: DateTime(2026, 6, 20),
        createdAt: DateTime(2026, 5, 1),
        isPaid: false,
      ),
    );
    await (await legacy
            .openBox<RecurringTransactionModel>('recurring_transactions_box'))
        .put(
      'rt',
      RecurringTransactionModel(
        id: 'rt1',
        userId: 'u',
        walletId: 'w1',
        title: 'Kira',
        tag: 'bills.rent',
        amount: 100,
        type: TransactionTypeModel.expense,
        frequency: RecurringFrequency.monthly,
        nextExecutionDate: DateTime(2026, 3, 25),
        anchorDay: 25,
        isActive: true,
      ),
    );
    await legacy.close();

    final current = currentHive();
    await expectLater(
      Future.wait([
        current.openBox<WalletModel>('wallets'),
        current.openBox<InvestmentModel>('investments_box'),
        current.openBox<DebtModel>('debts'),
        current.openBox<ReceivableModel>('receivables'),
        current
            .openBox<RecurringTransactionModel>('recurring_transactions_box'),
      ]),
      completes,
    );
    await current.close();
  });
}

// --- Eski sürümü taklit eden yazıcılar ------------------------------------
//
// Her biri üretilen/elle yazılan adapter'ın `write`ının, ilgili alan EKLENMEDEN
// ÖNCEKİ hâlidir. `read` çağrılmaz: bu sınıflar yalnız diske eski biçimi
// koymak için var.

class _LegacyWalletWriter extends TypeAdapter<WalletModel> {
  @override
  final int typeId = 0;

  @override
  WalletModel read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, WalletModel obj) {
    writer
      ..writeByte(14) // v10 öncesi: alan 14 (categoryIds) YOK
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.balance)
      ..writeByte(4)
      ..write(obj.debt)
      ..writeByte(5)
      ..write(obj.credit)
      ..writeByte(6)
      ..write(obj.investment)
      ..writeByte(7)
      ..write(obj.colorHex)
      ..writeByte(8)
      ..write(obj.iconName)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.sortOrder)
      ..writeByte(12)
      ..write(obj.openingBalance)
      ..writeByte(13)
      ..write(obj.currency);
  }
}

/// v12 öncesi (şema 10-11) cüzdan: alan 14'e kadar, alan 15 (kredi kartı) YOK.
class _LegacyV11WalletWriter extends TypeAdapter<WalletModel> {
  @override
  final int typeId = 0;

  @override
  WalletModel read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, WalletModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.balance)
      ..writeByte(4)
      ..write(obj.debt)
      ..writeByte(5)
      ..write(obj.credit)
      ..writeByte(6)
      ..write(obj.investment)
      ..writeByte(7)
      ..write(obj.colorHex)
      ..writeByte(8)
      ..write(obj.iconName)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.sortOrder)
      ..writeByte(12)
      ..write(obj.openingBalance)
      ..writeByte(13)
      ..write(obj.currency)
      ..writeByte(14)
      ..write(obj.categoryIds);
  }
}

class _LegacyTransactionWriter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 1;

  @override
  TransactionModel read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(11) // v11 öncesi: alan 11-13 YOK
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.walletId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.tag)
      ..writeByte(5)
      ..write(obj.amount)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.type)
      ..writeByte(8)
      ..write(obj.isSystem)
      ..writeByte(9)
      ..write(obj.receiptFileName)
      ..writeByte(10)
      ..write(obj.reference);
  }
}

class _LegacyInvestmentWriter extends TypeAdapter<InvestmentModel> {
  @override
  final int typeId = 4;

  @override
  InvestmentModel read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, InvestmentModel obj) {
    writer
      ..writeByte(13) // v8 öncesi: 15 (unbookedCost) ve 16 (goalId) YOK
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.walletId)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.currentValue)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.color)
      ..writeByte(8)
      ..write(obj.dateAdded)
      ..writeByte(9)
      ..write(obj.symbol)
      ..writeByte(10)
      ..write(obj.returnRate)
      ..writeByte(12)
      ..write(obj.quantity)
      ..writeByte(14)
      ..write(obj.currency);
  }
}

class _LegacyDebtWriter extends TypeAdapter<DebtModel> {
  @override
  final int typeId = 6;

  @override
  DebtModel read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, DebtModel obj) {
    writer
      ..writeByte(13) // v6 öncesi: 13, 17, 18, 19, 20 YOK
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.walletId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.principalAmount)
      ..writeByte(6)
      ..write(obj.interestRate)
      ..writeByte(7)
      ..write(obj.termMonths)
      ..writeByte(8)
      ..write(obj.startDate)
      ..writeByte(9)
      ..write(obj.dueDate)
      ..writeByte(14)
      ..write(obj.payments)
      ..writeByte(15)
      ..write(obj.isPaid)
      ..writeByte(16)
      ..write(obj.notes);
  }
}

class _LegacyPaymentWriter extends TypeAdapter<PaymentModel> {
  @override
  final int typeId = 9;

  @override
  PaymentModel read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, PaymentModel obj) {
    writer
      ..writeByte(3) // v6 öncesi: 3 (id) ve 4 (overdueInterestPart) YOK
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.notes);
  }
}

class _LegacyReceivableWriter extends TypeAdapter<ReceivableModel> {
  @override
  final int typeId = 7;

  @override
  ReceivableModel read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, ReceivableModel obj) {
    writer
      ..writeByte(8) // v4 öncesi: 8 (createdAt) ve 9 (collectedAt) YOK
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.walletId)
      ..writeByte(3)
      ..write(obj.debtorName)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.isPaid)
      ..writeByte(7)
      ..write(obj.notes);
  }
}

class _LegacyRecurringWriter extends TypeAdapter<RecurringTransactionModel> {
  @override
  final int typeId = 11;

  @override
  RecurringTransactionModel read(BinaryReader reader) =>
      throw UnimplementedError();

  @override
  void write(BinaryWriter writer, RecurringTransactionModel obj) {
    writer
      ..writeByte(10) // v3 öncesi: 10 (anchorDay) YOK
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.walletId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.tag)
      ..writeByte(5)
      ..write(obj.amount)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.frequency)
      ..writeByte(8)
      ..write(obj.nextExecutionDate)
      ..writeByte(9)
      ..write(obj.isActive);
  }
}

/// Şema 15'in kart bilgisi yazıcısı: 7 alan (0–6); 7–9 YOK.
class _V15CardInfoWriter extends TypeAdapter<CreditCardInfoModel> {
  @override
  final int typeId = 17;

  @override
  CreditCardInfoModel read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, CreditCardInfoModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.bankName)
      ..writeByte(1)
      ..write(obj.last4)
      ..writeByte(2)
      ..write(obj.limit)
      ..writeByte(3)
      ..write(obj.closingDay)
      ..writeByte(4)
      ..write(obj.dueDay)
      ..writeByte(5)
      ..write(obj.paymentWalletId)
      ..writeByte(6)
      ..write(obj.lastStatement);
  }
}

/// Şema 15'in yatırım yazıcısı: 15 alan; 17 (isPrimary) YOK.
class _V15InvestmentWriter extends TypeAdapter<InvestmentModel> {
  @override
  final int typeId = 4;

  @override
  InvestmentModel read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, InvestmentModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.walletId)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.currentValue)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.color)
      ..writeByte(8)
      ..write(obj.dateAdded)
      ..writeByte(9)
      ..write(obj.symbol)
      ..writeByte(10)
      ..write(obj.returnRate)
      ..writeByte(12)
      ..write(obj.quantity)
      ..writeByte(14)
      ..write(obj.currency)
      ..writeByte(15)
      ..write(obj.unbookedCost)
      ..writeByte(16)
      ..write(obj.goalId);
  }
}
