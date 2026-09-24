import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter_test/flutter_test.dart';

WalletEntity _w(String id, {String? owner, bool card = false}) => WalletEntity(
      id: id,
      userId: 'u',
      name: id,
      balance: 0,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF000000',
      iconName: 'wallet',
      createdAt: DateTime(2026, 1, 1),
      openingBalance: 0,
      creditCard: card || owner != null
          ? CreditCardInfo(closingDay: 15, dueDay: 25, paymentWalletId: owner)
          : null,
    );

void main() {
  final bank = _w('bank');
  final cash = _w('cash');
  final bonus = _w('bonus', owner: 'bank');
  final world = _w('world', owner: 'bank');
  final orphan = _w('orphan', card: true);
  final gone = _w('gone', owner: 'deleted');
  final cardOfCard = _w('cc', owner: 'orphan');
  final self = _w('self', owner: 'self');
  final all = [bank, bonus, cash, world, orphan, gone, cardOfCard, self];

  test('cardOwner: yalnız var olan DÜZ cüzdan sahip olabilir', () {
    expect(cardOwner(bonus, all), bank);
    expect(cardOwner(bank, all), isNull, reason: 'düz cüzdan');
    expect(cardOwner(orphan, all), isNull, reason: 'sahip seçilmemiş');
    expect(cardOwner(gone, all), isNull, reason: 'sahibi silinmiş');
    expect(cardOwner(cardOfCard, all), isNull,
        reason: 'kart kartın sahibi değil');
    expect(cardOwner(self, all), isNull, reason: 'kendi kendinin sahibi değil');
  });

  test('cardsOf: sahibin kartları, liste sırasıyla', () {
    expect(cardsOf('bank', all), [bonus, world]);
    expect(cardsOf('cash', all), isEmpty);
    expect(cardsOf('orphan', all), isEmpty);
    expect(cardsOf(null, all), isEmpty);
  });

  test('accountOf: bağlı kartta sahibi, diğerlerinde kendisi', () {
    expect(accountOf(bonus, all), bank);
    expect(accountOf(bank, all), bank);
    expect(accountOf(orphan, all), orphan);
  });

  test('topLevelWallets: düz cüzdanlar + YETİM kartlar; bağlılar gizli', () {
    expect(topLevelWallets(all), [bank, cash, orphan, gone, cardOfCard, self]);
  });

  test('walletsInFamilyOrder: kart sahibinin hemen ardından', () {
    expect(walletsInFamilyOrder(all).take(4), [bank, bonus, world, cash]);
    // Hiçbir cüzdan kaybolmaz ya da çiftlenmez.
    expect(walletsInFamilyOrder(all).toSet(), all.toSet());
    expect(walletsInFamilyOrder(all), hasLength(all.length));
  });

  test('familyLabel', () {
    expect(familyLabel(bonus, all), 'bank › bonus');
    expect(familyLabel(orphan, all), 'orphan');
  });

  group('netBreakdown', () {
    WalletEntity money(String id, double balance,
            {String currency = 'TRY', bool card = false}) =>
        _w(id, card: card).copyWith(balance: balance, currency: currency);

    test('kart yoksa null (kırılım gösterilmez)', () {
      expect(netBreakdown([money('a', 100)], rateToTry: (_) => null), isNull);
    });

    test('hesaplar − kart borçları; döviz TL\'ye çevrilir', () {
      final b = netBreakdown([
        money('a', 13000),
        money('usd', 100, currency: 'USD'),
        money('c', -3700, card: true),
      ], rateToTry: (c) => c == 'USD' ? 40 : null)!;
      expect(b.accounts, 17000);
      expect(b.cardDebt, 3700);
      expect(b.net, 13300);
    });

    test('kur eksikse null (eksik toplam yanıltır)', () {
      expect(
        netBreakdown([
          money('usd', 100, currency: 'USD'),
          money('c', -1, card: true),
        ], rateToTry: (_) => null),
        isNull,
      );
    });
  });
}
