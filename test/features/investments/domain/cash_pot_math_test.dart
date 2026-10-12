import 'dart:ui';

import 'package:cunehat/features/investments/domain/cash_pot_math.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter_test/flutter_test.dart';

InvestmentEntity pot({double balance = 1000, double unbooked = 0}) =>
    InvestmentEntity(
      id: 'pot',
      userId: 'u',
      walletId: 'w',
      name: 'Acil durum',
      amount: balance,
      currentValue: balance,
      type: InvestmentType.cash,
      color: const Color(0xFF26A69A),
      dateAdded: DateTime(2026, 9, 1),
      unbookedCost: unbooked,
    );

InvestmentEntity gold({double cost = 500, double unbooked = 0}) =>
    InvestmentEntity(
      id: 'g',
      userId: 'u',
      walletId: 'w',
      name: 'Altın',
      amount: cost,
      currentValue: cost,
      type: InvestmentType.gold,
      color: const Color(0xFFFFC107),
      dateAdded: DateTime(2026, 9, 1),
      unbookedCost: unbooked,
    );

void main() {
  group('takeFromPot', () {
    test('bakiye düşer, işlenmiş maliyet varlığa geçer', () {
      final r = takeFromPot(pot(), 400);
      expect(r.pot.amount, 600);
      expect(r.pot.currentValue, 600);
      expect(r.pot.bookedCost, 600);
      expect(r.movedBooked, 400);
    });

    test('kasadaki işlenmemiş (kâr) para önce işlenmişten sonra düşer', () {
      // 1000 bakiye: 700 cüzdandan geldi, 300 önceki satışın kârı.
      final r = takeFromPot(pot(unbooked: 300), 900);
      expect(r.movedBooked, 700);
      expect(r.pot.amount, 100);
      expect(r.pot.bookedCost, 0);
      expect(r.pot.unbookedCost, 100);
    });
  });

  group('putIntoPot', () {
    test('kârlı satışta kâr kasada işlenmemiş kalır', () {
      final p = putIntoPot(pot(balance: 0), 800, booked: 500);
      expect(p.amount, 800);
      expect(p.bookedCost, 500);
      expect(p.unbookedCost, 300);
    });

    test('zararlı satışta işlenmiş kısım bakiyeyi aşamaz', () {
      final p = putIntoPot(pot(balance: 0), 400, booked: 500);
      expect(p.amount, 400);
      expect(p.bookedCost, 400);
      expect(p.unbookedCost, 0);
    });
  });

  test('withdrawFromPot: işlenmiş kısım önce düşer', () {
    final p = withdrawFromPot(pot(unbooked: 300), 500);
    expect(p.amount, 500);
    expect(p.bookedCost, 200);
    expect(p.unbookedCost, 300);
  });

  group('bookAssetFromPot', () {
    test('yeni kayıt: işlenmemiş kısım = maliyet − geçen işlenmiş', () {
      final a = bookAssetFromPot(gold(cost: 900),
          cost: 900, movedBooked: 700, isNew: true);
      expect(a.unbookedCost, 200);
      expect(a.bookedCost, 700);
    });

    test('katkı: var olan işlenmemiş kısmın üstüne eklenir', () {
      final a = bookAssetFromPot(gold(cost: 1500, unbooked: 100),
          cost: 1000, movedBooked: 1000, isNew: false);
      expect(a.unbookedCost, 100);
      expect(a.bookedCost, 1400);
    });
  });

  test('para kasadan varlığa geçip geri dönünce toplam işlenmiş korunur', () {
    // Silme iadeleri (bookedCost) toplamı, hareketlerden bağımsız olarak
    // cüzdandan çıkan tutara eşit kalmalı: çift iade ya da kayıp iade yok.
    final p0 = pot(balance: 1000);
    final take = takeFromPot(p0, 600);
    final asset = bookAssetFromPot(gold(cost: 600),
        cost: 600, movedBooked: take.movedBooked, isNew: true);
    expect(take.pot.bookedCost + asset.bookedCost, 1000);

    // Varlık 750'ye satılıp bedel kasaya girer.
    final back = putIntoPot(take.pot, 750, booked: asset.bookedCost);
    expect(back.amount, 1150);
    expect(back.bookedCost, 1000);
    expect(back.unbookedCost, 150);
  });

  group('correctPotBalance (bakiye düzeltme — aktarım DEĞİL)', () {
    test('artış işlenmemiş kısma yazılır; işlenmiş maliyet değişmez', () {
      final p = correctPotBalance(pot(balance: 1000), 1400);
      expect(p.amount, 1400);
      expect(p.currentValue, 1400);
      expect(p.bookedCost, 1000);
      expect(p.unbookedCost, 400);
    });

    test('azalış önce işlenmemiş kısımdan düşer', () {
      final p = correctPotBalance(pot(balance: 1000, unbooked: 300), 800);
      expect(p.amount, 800);
      expect(p.bookedCost, 700);
      expect(p.unbookedCost, 100);
    });

    test('işlenmiş kısmın altına inilirse işlenmiş kısım bakiyeye kenetlenir',
        () {
      final p = correctPotBalance(pot(balance: 1000, unbooked: 300), 500);
      expect(p.amount, 500);
      expect(p.bookedCost, 500);
      expect(p.unbookedCost, 0);
    });

    test('sıfıra çekilebilir; eksi rakam sıfır sayılır', () {
      expect(correctPotBalance(pot(), 0).amount, 0);
      final negative = correctPotBalance(pot(), -50);
      expect(negative.amount, 0);
      expect(negative.bookedCost, 0);
    });

    test('kuruşa yuvarlar', () {
      expect(correctPotBalance(pot(), 123.456).amount, 123.46);
    });
  });

  group('ana kasa', () {
    InvestmentEntity named(String id, {bool primary = false}) =>
        pot().copyWith(id: id, name: id, isPrimary: primary);

    test('primaryPotOf: işaretli kasa; yoksa null', () {
      expect(primaryPotOf([named('a'), named('b')]), isNull);
      expect(primaryPotOf([named('a'), named('b', primary: true)])!.id, 'b');
      expect(primaryPotOf(const []), isNull);
    });

    test('primaryPotOf: kasa OLMAYAN kayıttaki işaret sayılmaz', () {
      expect(primaryPotOf([gold().copyWith(isPrimary: true)]), isNull);
    });

    test('primaryPotFirst: ana kasa başa gelir, kalanın sırası korunur', () {
      final ordered = primaryPotFirst(
          [named('c'), named('a'), named('b', primary: true), named('d')]);
      expect([for (final p in ordered) p.id], ['b', 'c', 'a', 'd']);
    });

    test('primaryPotFirst: işaret yoksa liste aynen döner', () {
      final ordered = primaryPotFirst([named('c'), named('a')]);
      expect([for (final p in ordered) p.id], ['c', 'a']);
    });
  });
}
