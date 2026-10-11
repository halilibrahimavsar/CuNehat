import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/core/services/transfer_service.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/widgets/transfer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransferService extends Mock implements TransferService {}

class _MockRates extends Mock implements ExchangeRateService {}

WalletEntity _wallet(String id, String name, double balance) => WalletEntity(
      id: id,
      userId: 'u',
      name: name,
      balance: balance,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF2196F3',
      iconName: 'wallet',
      createdAt: DateTime(2025, 1, 1),
      openingBalance: balance,
    );

/// Transfer onayı (UX Tur 3c).
///
/// ÖNCE: her transferde "emin misiniz?" diyaloğu + başarıda ayrıca "Geri al".
/// Form tutarı, kaynağı ve hedefi zaten gösteriyordu; onay yalnız sürtünmeydi.
void main() {
  late _MockTransferService service;
  final cash = _wallet('a', 'Nakit', 1000);
  final bank = _wallet('b', 'Banka', 5000);

  setUpAll(() => registerFallbackValue(cash));

  setUp(() {
    Intl.defaultLocale = 'tr_TR';
    service = _MockTransferService();
    getIt.registerSingleton<TransferService>(service);
    getIt.registerSingleton<ExchangeRateService>(_MockRates());
    when(() => service.transfer(
          from: any(named: 'from'),
          to: any(named: 'to'),
          amount: any(named: 'amount'),
          date: any(named: 'date'),
        )).thenAnswer((_) async => const TransferOutcome(
          result: TransferResult.success,
          transactionIds: ['t1', 't2'],
          fromWalletId: 'a',
          toWalletId: 'b',
          pairId: 'p',
        ));
  });

  tearDown(() async => getIt.reset());

  Future<AppLocalizations> pumpAndFill(
    WidgetTester tester,
    String amount,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      scaffoldMessengerKey: appMessengerKey,
      locale: const Locale('tr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => TransferSheet.show(
              context,
              wallets: [cash, bank],
              initialFrom: cash,
            ),
            child: const Text('aç'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), amount);
    await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(const Locale('tr'));
  }

  Future<void> submit(WidgetTester tester, AppLocalizations l10n) async {
    final button = find.widgetWithText(ElevatedButton, l10n.transferEt);
    final target =
        button.evaluate().isNotEmpty ? button : find.text(l10n.transferEt).last;
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('bakiye yetiyorsa onay SORULMAZ; transfer doğrudan yapılır',
      (tester) async {
    final l10n = await pumpAndFill(tester, '250');
    // Kendi cüzdanları arasında para taşıyan kullanıcı "ödeme" yapmıyor:
    // alanın adı yalnız "Tutar".
    expect(find.text('${l10n.tutarHint} *'), findsOneWidget);
    expect(find.text(l10n.labelOdemeTutari), findsNothing);
    await submit(tester, l10n);

    expect(find.text(l10n.transferOnayBasligi), findsNothing);
    verify(() => service.transfer(
          from: any(named: 'from'),
          to: any(named: 'to'),
          amount: 250,
          date: any(named: 'date'),
        )).called(1);
    // Yanlışlık için güvence yerinde: başarı mesajında "Geri al".
    expect(find.text(l10n.geriAl), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('tutar bakiyeyi aşıyorsa durup sorar; vazgeçilirse yazılmaz',
      (tester) async {
    final l10n = await pumpAndFill(tester, '2500');
    await submit(tester, l10n);

    expect(find.text(l10n.transferOnayBasligi), findsOneWidget);
    expect(find.textContaining('eksiye düşer'), findsOneWidget);

    await tester.tap(find.text(l10n.iptal));
    await tester.pumpAndSettle();
    verifyNever(() => service.transfer(
          from: any(named: 'from'),
          to: any(named: 'to'),
          amount: any(named: 'amount'),
          date: any(named: 'date'),
        ));
  });
}
