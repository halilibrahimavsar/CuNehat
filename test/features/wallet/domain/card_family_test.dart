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

    test('kart, borç ve alacak yoksa null (kırılım gösterilmez)', () {
      expect(netBreakdown([money('a', 100)], rateToTry: (_) => null), isNull);
    });

    test('REGRESYON: kredi ve alacak da NET\'e girer (kart olmasa bile)', () {
      // Kredinin ana parası hesaba gelir olarak girdi (13.000'in 10.000'i);
      // net onu düşmeseydi kullanıcı 10.000 TL zengin görünürdü.
      final b = netBreakdown([
        money('a', 13000).copyWith(debt: 10000, credit: 500),
      ], rateToTry: (_) => null)!;
      expect(b.accounts, 13000);
      expect(b.loans, 10000);
      expect(b.receivables, 500);
      expect(b.cardDebt, 0);
      expect(b.net, 3500);
    });

    test('dört kalem birlikte: hesaplar − kart − kredi + alacak', () {
      final b = netBreakdown([
        money('a', 20000).copyWith(debt: 6000, credit: 1000),
        money('c', -3700, card: true),
      ], rateToTry: (_) => null)!;
      expect(b.net, 20000 - 3700 - 6000 + 1000);
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

  group('debtOverview', () {
    WalletEntity w(String id,
            {double balance = 0,
            double debt = 0,
            String? owner,
            bool card = false,
            String currency = 'TRY'}) =>
        _w(id, owner: owner, card: card)
            .copyWith(balance: balance, debt: debt, currency: currency);

    test('REGRESYON: kart borcu Borç toplamına girer (eskiden yalnız modül)',
        () {
      final bank = w('bank', balance: 8000, debt: 0);
      final bonus = w('bonus', balance: -1200, owner: 'bank');
      final o = debtOverview(bank, [bank, bonus]);
      expect(o.loans, 0);
      expect(o.cards, 1200);
      expect(o.total, 1200);
    });

    test('krediler + kartlar; artıdaki (fazla ödenmiş) kart borç değil', () {
      final bank = w('bank', debt: 12000);
      final a = w('a', balance: -1200, owner: 'bank');
      final b = w('b', balance: 50, owner: 'bank');
      final o = debtOverview(bank, [bank, a, b]);
      expect(o.loans, 12000);
      expect(o.cards, 1200);
      expect(o.total, 13200);
    });

    test('bağlı kart aktifken sahibinin ailesi hesaplanır', () {
      final bank = w('bank', debt: 100);
      final a = w('a', balance: -50, owner: 'bank');
      expect(debtOverview(a, [bank, a]).total, 150);
    });

    test('farklı birimdeki kart toplanmaz (tutar tek birimde yazılır)', () {
      final bank = w('bank');
      final usd = w('usd', balance: -10, owner: 'bank', currency: 'USD');
      expect(debtOverview(bank, [bank, usd]).cards, 0);
    });

    test('yetim kart kendi borcunu taşır', () {
      final orphan = w('orphan', balance: -300, card: true);
      final o = debtOverview(orphan, [orphan]);
      expect(o.cards, 300);
      expect(o.loans, 0);
    });
  });
}
