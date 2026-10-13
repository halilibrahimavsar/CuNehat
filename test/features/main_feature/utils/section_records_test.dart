import 'dart:async';

import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/investments/data/datasource/goal_local_datasource.dart';
import 'package:cunehat/features/investments/data/models/goal_model.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/main_feature/utils/section_records.dart';
import 'package:cunehat/features/wallet/data/models/credit_card_info_model.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class _MockHive extends Mock implements HiveInterface {}

class _MockBox<T> extends Mock implements Box<T> {}

class _MockWallet extends Mock implements WalletModel {}

class _MockCard extends Mock implements CreditCardInfoModel {}

void main() {
  late _MockHive hive;
  late _MockBox<InvestmentModel> investments;
  late _MockBox<GoalModel> goals;
  late _MockBox<DebtModel> debts;
  late _MockBox<ReceivableModel> receivables;
  late _MockBox<WalletModel> wallets;
  late SectionRecords records;

  void stubBox<T>(String name, _MockBox<T> box, {bool notEmpty = false}) {
    when(() => hive.isBoxOpen(name)).thenReturn(true);
    when(() => hive.box<T>(name)).thenReturn(box);
    when(() => box.isNotEmpty).thenReturn(notEmpty);
  }

  WalletModel wallet({required bool card}) {
    final w = _MockWallet();
    when(() => w.creditCard).thenReturn(card ? _MockCard() : null);
    return w;
  }

  setUp(() {
    hive = _MockHive();
    investments = _MockBox();
    goals = _MockBox();
    debts = _MockBox();
    receivables = _MockBox();
    wallets = _MockBox();

    stubBox(SectionRecords.investmentsBox, investments);
    stubBox(GoalLocalDataSource.boxName, goals);
    stubBox(SectionRecords.debtsBox, debts);
    stubBox(SectionRecords.receivablesBox, receivables);
    stubBox(SectionRecords.walletsBox, wallets);
    // Sahte cüzdanlar `when` çağırır; iç içe `when` olmasın diye liste önce
    // kurulur.
    final plain = [wallet(card: false)];
    when(() => wallets.values).thenReturn(plain);

    records = SectionRecords(hive);
  });

  group('Birikim', () {
    test('boş kutularla kayıt yoktur', () {
      expect(records.savingsHasRecords, isFalse);
    });

    test('bir varlık / kasa yeter', () {
      when(() => investments.isNotEmpty).thenReturn(true);
      expect(records.savingsHasRecords, isTrue);
    });

    test('varlığı olmayan HEDEF de kayıttır', () {
      when(() => goals.isNotEmpty).thenReturn(true);
      expect(records.savingsHasRecords, isTrue);
    });

    test('borç kayıtları Birikim\'i etkilemez', () {
      when(() => debts.isNotEmpty).thenReturn(true);
      expect(records.savingsHasRecords, isFalse);
    });
  });

  group('Borç', () {
    test('boş kutularla kayıt yoktur', () {
      expect(records.debtHasRecords, isFalse);
    });

    test('bir borç yeter', () {
      when(() => debts.isNotEmpty).thenReturn(true);
      expect(records.debtHasRecords, isTrue);
    });

    test('bir alacak yeter', () {
      when(() => receivables.isNotEmpty).thenReturn(true);
      expect(records.debtHasRecords, isTrue);
    });

    test('kredi kartı Borç bölümünde yaşar: kartı olanın bölümü doludur', () {
      final withCard = [wallet(card: false), wallet(card: true)];
      when(() => wallets.values).thenReturn(withCard);
      expect(records.debtHasRecords, isTrue);
    });

    test('düz cüzdan kayıt sayılmaz', () {
      expect(records.debtHasRecords, isFalse);
    });
  });

  test('kutu açık değilse "kayıt yok" sayılır, fırlatmaz', () {
    for (final name in [
      SectionRecords.investmentsBox,
      GoalLocalDataSource.boxName,
      SectionRecords.debtsBox,
      SectionRecords.receivablesBox,
      SectionRecords.walletsBox,
    ]) {
      when(() => hive.isBoxOpen(name)).thenReturn(false);
    }

    expect(records.savingsHasRecords, isFalse);
    expect(records.debtHasRecords, isFalse);
    verifyNever(() => hive.box<InvestmentModel>(any()));
  });

  group('canlı izleme', () {
    late Map<String, StreamController<BoxEvent>> events;

    setUp(() {
      events = {};
      void watch<T>(String name, _MockBox<T> box) {
        final controller = StreamController<BoxEvent>.broadcast();
        events[name] = controller;
        when(() => box.watch()).thenAnswer((_) => controller.stream);
      }

      watch(SectionRecords.investmentsBox, investments);
      watch(GoalLocalDataSource.boxName, goals);
      watch(SectionRecords.debtsBox, debts);
      watch(SectionRecords.receivablesBox, receivables);
      watch(SectionRecords.walletsBox, wallets);
    });

    tearDown(() async {
      for (final c in events.values) {
        await c.close();
      }
    });

    test('beş kutudan herhangi biri değişince haber verir', () async {
      var notified = 0;
      final sub = records.changes.listen((_) => notified++);

      for (final controller in events.values) {
        controller.add(BoxEvent('k', null, false));
      }
      await Future<void>.delayed(Duration.zero);

      expect(notified, events.length);
      await sub.cancel();
    });

    test('dinleyici bırakınca kutu abonelikleri de bırakılır', () async {
      final sub = records.changes.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(events.values.every((c) => c.hasListener), isTrue);

      await sub.cancel();
      await Future<void>.delayed(Duration.zero);

      expect(events.values.any((c) => c.hasListener), isFalse);
    });
  });

  group('transactionCount', () {
    test('defter kutusu açık değilse 0', () {
      when(() => hive.isBoxOpen(SectionRecords.transactionsBox))
          .thenReturn(false);

      expect(records.transactionCount, 0);
    });

    test('açıksa kayıt sayısı — kayıtlar OKUNMADAN', () {
      final box = _MockBox<TransactionModel>();
      when(() => hive.isBoxOpen(SectionRecords.transactionsBox))
          .thenReturn(true);
      when(() => hive.box<TransactionModel>(SectionRecords.transactionsBox))
          .thenReturn(box);
      when(() => box.length).thenReturn(271);

      expect(records.transactionCount, 271);
      verifyNever(() => box.values);
    });
  });
}
