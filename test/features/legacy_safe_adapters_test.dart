import 'dart:io';

import 'package:cunehat/core/models/legacy_safe_adapters.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_calc_mode_adapter.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_type_adapter.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/data/models/investment_type_adapter.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/color_adapter.dart';
import 'package:cunehat/features/recurring_transactions/data/models/recurring_transaction_model.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBinaryReader extends Mock implements BinaryReader {}

/// `numOfFields` + (indeks, değer) çiftlerini üreten sahte okuyucu —
/// üretilen adapter'ların kareyi okuma biçiminin birebir aynısı.
BinaryReader legacyRecord(Map<int, dynamic> fields) {
  final reader = MockBinaryReader();
  final bytes = <int>[fields.length, ...fields.keys];
  when(() => reader.readByte()).thenAnswer((_) => bytes.removeAt(0));
  final values = [...fields.values];
  when(() => reader.read()).thenAnswer((_) => values.removeAt(0));
  return reader;
}

/// Geç eklenmiş non-null alanları olan modeller.
///
/// Üretilen adapter eski kayıtta `null as double` yapıp **TypeError**
/// fırlatıyordu; ölçüldü, beş modelin beşi de. Bedeli tek bir kayıt değil:
/// `openBox` kutunun bütün karelerini okuduğu için TEK bir eski kayıt o
/// kutuyu tamamen açılamaz hâle getirir — yani uygulama açılmaz.
void main() {
  final created = DateTime(2026, 1, 1);

  group('eski kayıt (geç eklenen alan YOK) okunabilir', () {
    test('InvestmentModel — alan 15 (unbookedCost, v8) yok', () {
      final model = SafeInvestmentModelAdapter().read(legacyRecord({
        0: 'i1',
        1: 'u',
        2: 'w',
        3: 'Gram Altın',
        4: 1000.0,
        5: 1200.0,
        6: InvestmentType.gold,
        7: const Color(0xFFFFD700),
        8: created,
        9: 'gram-altin',
        10: null,
        12: 3.0,
      }));

      // Kavram yokken hiçbir maliyet "işlenmemiş" değildi.
      expect(model.unbookedCost, 0);
      expect(model.amount, 1000.0);
      expect(model.goalId, isNull);
      expect(model.currency, isNull);
    });

    test('ReceivableModel — alan 8 (createdAt, v4) yok', () {
      final due = DateTime(2026, 6, 20);
      final model = SafeReceivableModelAdapter().read(legacyRecord({
        0: 'r1',
        1: 'u',
        2: 'w',
        3: 'Ali',
        4: 500.0,
        5: due,
        6: false,
        7: null,
      }));

      // Vade, kayıttaki TEK tarih ve alacağın kendi zamanına en yakın olanı;
      // "bugün"e düşmek ters kayıtları yaşanmamış bir aya yazardı.
      expect(model.createdAt, due);
      expect(model.collectedAt, isNull);
    });

    test('RecurringTransactionModel — alan 10 (anchorDay, v3) yok', () {
      final next = DateTime(2026, 3, 29);
      final model = SafeRecurringTransactionModelAdapter().read(legacyRecord({
        0: 'rt1',
        1: 'u',
        2: 'w',
        3: 'Kira',
        4: 'Fatura',
        5: 7500.0,
        6: TransactionTypeModel.expense,
        7: RecurringFrequency.monthly,
        8: next,
        9: true,
      }));

      // Çapa vadenin gününden türetilir — `startingOn` fabrikası da öyle.
      expect(model.anchorDay, 29);
    });

    test('PaymentModel — alan 3 (id) ve 4 (overdueInterestPart), v6 yok', () {
      final date = DateTime(2026, 2, 10);
      final model = SafePaymentModelAdapter().read(legacyRecord({
        0: date,
        1: 250.0,
        2: 'not',
      }));

      expect(model.overdueInterestPart, 0);
      expect(model.id, isNotEmpty);

      // Kimlik TÜRETİLİR, üretilmez: her okumada yeni bir UUID vermek
      // ödemenin düzenlenmesini/silinmesini imkânsız kılardı.
      final again = SafePaymentModelAdapter().read(legacyRecord({
        0: date,
        1: 250.0,
        2: 'not',
      }));
      expect(again.id, model.id, reason: 'kimlik okumadan okumaya değişti');
    });

    test('DebtModel — alan 13/17/18/19/20 yok', () {
      final model = SafeDebtModelAdapter().read(legacyRecord({
        0: 'd1',
        1: 'u',
        2: 'w',
        3: 'İhtiyaç kredisi',
        4: DebtType.bankLoan,
        5: 10000.0,
        6: 0.0,
        7: 12,
        8: created,
        9: null,
        14: <dynamic>[],
        15: false,
        16: null,
      }));

      // Yöntem TAHMİN EDİLMEZ: `none` = faizsiz, toplam = ana para.
      // Tahmin etmek borcun büyüklüğünü sessizce değiştirirdi —
      // `DebtCalcMode`'un var oluş sebebi tam olarak budur.
      expect(model.calcMode, DebtCalcMode.none);
      expect(model.expectedTotalAmount, 10000.0);
      expect(model.overdueInterestRate, 0);
      expect(model.principalToWallet, isTrue);
      expect(model.counterparty, '');
      expect(model.payments, isEmpty);
    });
  });

  group('gidiş-dönüş: ezilen read, ÜRETİLEN write ile senkron', () {
    // Bu grup kaymanın bekçisidir: yazılan ama burada okunmayan bir alan,
    // ilk yazımda SESSİZCE kaybolur. Yeni alan eklenirken bu testler de
    // güncellenmeli.
    late Directory dir;

    setUpAll(() async {
      dir = await Directory.systemTemp.createTemp('cunehat_safe_adapters');
      Hive.init(dir.path);
      void reg<T>(TypeAdapter<T> a) {
        if (!Hive.isAdapterRegistered(a.typeId)) Hive.registerAdapter(a);
      }

      reg(InvestmentTypeAdapter());
      reg(ColorAdapter());
      reg(DebtTypeAdapter());
      reg(DebtCalcModeAdapter());
      reg(TransactionTypeModelAdapter());
      reg(RecurringFrequencyAdapter());
      reg(SafeInvestmentModelAdapter());
      reg(SafeDebtModelAdapter());
      reg(SafePaymentModelAdapter());
      reg(SafeReceivableModelAdapter());
      reg(SafeRecurringTransactionModelAdapter());
    });

    tearDownAll(() async {
      await Hive.close();
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    Future<T> roundTrip<T>(String boxName, T value) async {
      final box = await Hive.openBox<T>(boxName);
      await box.put('k', value);
      await box.close();
      final reopened = await Hive.openBox<T>(boxName);
      return reopened.get('k') as T;
    }

    test('InvestmentModel tüm alanlarıyla geri gelir', () async {
      final model = InvestmentModel(
        id: 'i1',
        userId: 'u',
        walletId: 'w',
        name: 'Apple',
        amount: 1000.0,
        currentValue: 1234.56,
        type: InvestmentType.stock,
        color: const Color(0xFF2196F3),
        dateAdded: created,
        symbol: 'AAPL',
        returnRate: 12.5,
        quantity: 7.0,
        goalId: 'g1',
        currency: 'USD',
        unbookedCost: 250.0,
      );

      final back = await roundTrip('inv_rt', model);

      expect(back.id, model.id);
      expect(back.userId, model.userId);
      expect(back.walletId, model.walletId);
      expect(back.name, model.name);
      expect(back.amount, model.amount);
      expect(back.currentValue, model.currentValue);
      expect(back.type, model.type);
      expect(back.color, model.color);
      expect(back.dateAdded, model.dateAdded);
      expect(back.symbol, model.symbol);
      expect(back.returnRate, model.returnRate);
      expect(back.quantity, model.quantity);
      expect(back.goalId, model.goalId);
      expect(back.currency, model.currency);
      expect(back.unbookedCost, model.unbookedCost);
    });

    test('DebtModel + PaymentModel tüm alanlarıyla geri gelir', () async {
      final model = DebtModel(
        id: 'd1',
        userId: 'u',
        walletId: 'w',
        title: 'Kredi',
        counterparty: 'Banka',
        type: DebtType.bankLoan,
        calcMode: DebtCalcMode.amortizedWithTaxes,
        principalAmount: 10000.0,
        interestRate: 2.5,
        termMonths: 24,
        overdueInterestRate: 1.5,
        startDate: created,
        dueDate: DateTime(2028, 1, 1),
        payments: [
          // Hive kareye RUNTIME tipe göre yazar: düz `Payment` için kayıtlı
          // adapter yoktur, `DebtModel.fromEntity` de dönüştürerek yazar.
          PaymentModel(
            id: 'p1',
            date: DateTime(2026, 2, 1),
            amount: 500.0,
            overdueInterestPart: 25.0,
            notes: 'ilk',
          ),
        ],
        isPaid: false,
        notes: 'not',
        expectedTotalAmount: 13000.0,
        principalToWallet: true,
      );

      final back = await roundTrip('debt_rt', model);

      expect(back.counterparty, 'Banka');
      expect(back.calcMode, DebtCalcMode.amortizedWithTaxes);
      expect(back.overdueInterestRate, 1.5);
      expect(back.expectedTotalAmount, 13000.0);
      expect(back.principalToWallet, isTrue);
      expect(back.interestRate, 2.5);
      expect(back.termMonths, 24);
      expect(back.startDate, created);
      expect(back.dueDate, DateTime(2028, 1, 1));
      expect(back.isPaid, isFalse);
      expect(back.notes, 'not');
      expect(back.payments, hasLength(1));
      expect(back.payments.single.id, 'p1');
      expect(back.payments.single.amount, 500.0);
      expect(back.payments.single.overdueInterestPart, 25.0);
      expect(back.payments.single.notes, 'ilk');
    });

    test('ReceivableModel tüm alanlarıyla geri gelir', () async {
      final model = ReceivableModel(
        id: 'r1',
        userId: 'u',
        walletId: 'w',
        debtorName: 'Ali',
        amount: 500.0,
        dueDate: DateTime(2026, 6, 20),
        createdAt: created,
        collectedAt: DateTime(2026, 5, 1),
        isPaid: true,
        notes: 'not',
      );

      final back = await roundTrip('recv_rt', model);

      expect(back.createdAt, created);
      expect(back.collectedAt, DateTime(2026, 5, 1));
      expect(back.isPaid, isTrue);
      expect(back.notes, 'not');
      expect(back.dueDate, DateTime(2026, 6, 20));
      expect(back.amount, 500.0);
      expect(back.debtorName, 'Ali');
    });

    test('RecurringTransactionModel tüm alanlarıyla geri gelir', () async {
      final model = RecurringTransactionModel(
        id: 'rt1',
        userId: 'u',
        walletId: 'w',
        title: 'Kira',
        tag: 'Fatura',
        amount: 7500.0,
        type: TransactionTypeModel.expense,
        frequency: RecurringFrequency.monthly,
        nextExecutionDate: DateTime(2026, 3, 31),
        anchorDay: 31,
        isActive: true,
      );

      final back = await roundTrip('rec_rt', model);

      expect(back.anchorDay, 31);
      expect(back.isActive, isTrue);
      expect(back.frequency, RecurringFrequency.monthly);
      expect(back.type, TransactionTypeModel.expense);
      expect(back.nextExecutionDate, DateTime(2026, 3, 31));
      expect(back.amount, 7500.0);
      expect(back.tag, 'Fatura');
    });
  });

  group('kalıcı enum sıraları kilitli', () {
    // `DebtType`/`DebtCalcMode` sırası kendi test dosyasında zaten kilitli;
    // burada KALAN üç enum kilitleniyor. Üçü de diske INDEX (ya da index
    // tabanlı bir byte) yazar, yani üye sırası KALICI ŞEMADIR: araya üye
    // eklemek kayıtlı verinin anlamını sessizce değiştirir.
    // `CLAUDE.md`: "enum değerleri yalnız SONA eklenir".
    test('InvestmentType — yatırım TÜRÜ index ile saklanır', () {
      expect(InvestmentType.values.map((e) => e.name).toList(),
          ['stock', 'gold', 'custom']);
    });

    test('TransactionTypeModel — GELİR/GİDER işareti byte ile saklanır', () {
      // Sıranın kayması, kayıtlı her giderin gelire dönmesi demek.
      expect(TransactionTypeModel.values.map((e) => e.name).toList(),
          ['income', 'expense']);
    });

    test('RecurringFrequency — vade ilerletmesi buna bağlı', () {
      expect(RecurringFrequency.values.map((e) => e.name).toList(),
          ['daily', 'weekly', 'monthly', 'yearly']);
    });
  });

  group('bilinmeyen enum byte: DÜŞ, fırlatma', () {
    // Üretilen enum adapter'ları bilinmeyen byte'ta bir varsayılana düşer
    // (`TransactionTypeModel` → income, `RecurringFrequency` → daily).
    // Bu BİLİNÇLİ olarak korunuyor: fırlatmak tek bozuk baytın kutunun
    // TAMAMINI açılamaz hâle getirmesi demek olurdu — yani bir kaydın
    // işaretini kaybetmek yerine tüm defteri kaybetmek. Sıra kilidi
    // (yukarıdaki grup) zaten gerçek ve önlenebilir riski kapatıyor.
    test('TransactionTypeModel aralık dışı byte için fırlatmaz', () {
      final reader = MockBinaryReader();
      when(() => reader.readByte()).thenReturn(99);
      expect(TransactionTypeModelAdapter().read(reader),
          TransactionTypeModel.income);
    });

    test('RecurringFrequency aralık dışı byte için fırlatmaz', () {
      final reader = MockBinaryReader();
      when(() => reader.readByte()).thenReturn(99);
      expect(
          RecurringFrequencyAdapter().read(reader), RecurringFrequency.daily);
    });
  });
}
