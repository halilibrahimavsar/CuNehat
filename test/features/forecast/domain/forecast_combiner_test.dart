import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/forecast/domain/forecast_combiner.dart';
import 'package:cunehat/features/forecast/domain/forecast_engine.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bugün 30 Eki 2026. Hiçbir cüzdanda hız yok (kayıt kısa) → yol yalnız
/// planlı olaylarla çizilir, sayılar elle doğrulanabilir.
final _today = DateTime(2026, 10, 30);

WalletEntity _wallet(String id, double balance,
        {String currency = 'TRY', CreditCardInfo? card}) =>
    WalletEntity(
      id: id,
      userId: 'u',
      name: id,
      balance: balance,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF000000',
      iconName: 'x',
      createdAt: DateTime(2026, 10, 1),
      openingBalance: 0,
      currency: currency,
      creditCard: card,
    );

TransactionEntity _tx(String walletId, DateTime date, double amount,
        {bool income = false, bool system = false, String tag = 'food'}) =>
    TransactionEntity(
      id: '$walletId-${date.toIso8601String()}-$amount-$income',
      userId: 'u',
      walletId: walletId,
      title: tag,
      tag: tag,
      amount: amount,
      date: date,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      isSystem: system,
    );

Map<String, WalletForecast> _project(List<WalletForecastInput> inputs) =>
    ForecastEngine(
      today: _today,
      period: DateTimeRange(
          start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 31)),
      horizonDays: 30,
    ).projectAll(inputs);

/// Kesim 25 / son ödeme 5: 20 Eki'deki 300 ₺ 5 Kas'ta ödenir.
WalletForecastInput _card({String? payer}) => WalletForecastInput(
      wallet: _wallet('card', -300,
          card: CreditCardInfo(
              closingDay: 25, dueDay: 5, paymentWalletId: payer)),
      ledger: [_tx('card', DateTime(2026, 10, 20), 300)],
    );

BalancePoint _at(CombinedForecast c, DateTime day) =>
    c.path.firstWhere((p) => p.day == day);

void main() {
  test(
      'nakit yolu kart OLMAYAN cüzdanların toplamı; kart ödemesi ödeme '
      'hesabından BİR KEZ düşer', () {
    final c = combineForecasts(
      _project([
        WalletForecastInput(wallet: _wallet('a', 1000), ledger: const []),
        WalletForecastInput(wallet: _wallet('b', 500), ledger: const []),
        _card(payer: 'a'),
      ]).values,
      currency: 'TRY',
    );
    expect(c.path.first.expected, 1500);
    expect(_at(c, DateTime(2026, 11, 4)).expected, 1500);
    expect(_at(c, DateTime(2026, 11, 5)).expected, 1200);
    final payments =
        c.events.where((e) => e.kind == ForecastEventKind.cardPayment);
    expect(payments, hasLength(1));
    expect(payments.single.walletId, 'a');
    expect(payments.single.amount, -300);
  });

  test('ödeme hesabı bilinmeyen kartın ödemesi yine NAKİTTEN düşer', () {
    final c = combineForecasts(
      _project([
        WalletForecastInput(wallet: _wallet('a', 1000), ledger: const []),
        _card(),
      ]).values,
      currency: 'TRY',
    );
    expect(_at(c, DateTime(2026, 11, 5)).expected, 700);
    expect(
        c.events
            .where((e) => e.kind == ForecastEventKind.cardPayment)
            .single
            .amount,
        -300);
  });

  test('kendi cüzdanların arası ileri tarihli transfer toplamı DEĞİŞTİRMEZ',
      () {
    final day = DateTime(2026, 11, 3);
    final c = combineForecasts(
      _project([
        WalletForecastInput(
          wallet: _wallet('a', 700), // 1.000 − 300 (ileri tarihli çıkış)
          ledger: [_tx('a', day, 300, system: true, tag: 'Transfer')],
        ),
        WalletForecastInput(
          wallet: _wallet('b', 800), // 500 + 300 (ileri tarihli giriş)
          ledger: [
            _tx('b', day, 300, income: true, system: true, tag: 'Transfer')
          ],
        ),
      ]).values,
      currency: 'TRY',
    );
    expect(c.path.first.expected, 1500);
    expect(_at(c, day).expected, 1500);
  });

  test('başka birim kurla çevrilir; kuru bilinmeyen cüzdan DIŞARIDA kalır', () {
    final forecasts = _project([
      WalletForecastInput(wallet: _wallet('a', 1000), ledger: const []),
      WalletForecastInput(
          wallet: _wallet('usd', 100, currency: 'USD'), ledger: const []),
    ]).values;

    final withRate =
        combineForecasts(forecasts, currency: 'TRY', rates: {'USD': 30});
    expect(withRate.path.first.expected, 1000 + 100 * 30);
    expect(withRate.excluded, isEmpty);

    final noRate = combineForecasts(forecasts, currency: 'TRY');
    expect(noRate.path.first.expected, 1000);
    expect(noRate.excluded.single.walletId, 'usd');
  });

  test('dönem gideri kartları da sayar (harcama kartta yapılır)', () {
    final c = combineForecasts(
      _project([
        WalletForecastInput(
          wallet: _wallet('a', 1000),
          ledger: [_tx('a', DateTime(2026, 10, 10), 200)],
        ),
        // Kesim 25 / son ödeme 28: 20 Eki harcaması 28 Eki'de ödendi →
        // Ekim'e sayılır.
        WalletForecastInput(
          wallet: _wallet('card', -150,
              card: const CreditCardInfo(
                  closingDay: 25, dueDay: 28, paymentWalletId: 'a')),
          ledger: [_tx('card', DateTime(2026, 10, 20), 150)],
        ),
      ]).values,
      currency: 'TRY',
    );
    expect(c.period!.realizedExpense, 350);
  });

  test(
      'plan yolu da toplanır; yetim kart ödemesinin kesin kısmı nakitten düşer',
      () {
    final c = combineForecasts(
      _project([
        WalletForecastInput(wallet: _wallet('a', 1000), ledger: const []),
        WalletForecastInput(wallet: _wallet('b', 500), ledger: const []),
        _card(),
      ]).values,
      currency: 'TRY',
    );
    expect(c.path.first.planned, 1500);
    expect(_at(c, DateTime(2026, 11, 5)).planned, 1200);
    final orphan =
        c.events.singleWhere((e) => e.kind == ForecastEventKind.cardPayment);
    expect(orphan.knownAmount, -300);
  });
}
