import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_quick_start_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WalletQuickStartAction? result;
  var closed = false;

  Future<AppLocalizations> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    result = null;
    closed = false;
    await tester.pumpWidget(MaterialApp(
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
            onPressed: () async {
              result = await WalletQuickStartSheet.show(
                context,
                walletName: 'Nakit',
              );
              closed = true;
            },
            child: const Text('aç'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(const Locale('tr'));
  }

  testWidgets('tutamak sayfanın ORTASINDA durur', (tester) async {
    // Cihazda görüldü: sütun sola yaslı olduğu için tutamak sol kenardaydı.
    await open(tester);

    final handle =
        tester.getRect(find.byKey(const ValueKey('quick-start-handle')));
    expect(handle.center.dx, closeTo(400, 1));
  });

  testWidgets('"Şimdilik atla" atlama sonucuyla kapanır', (tester) async {
    final l10n = await open(tester);

    await tester.tap(find.text(l10n.walletQuickStartSkip));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, WalletQuickStartAction.skip);
  });

  group('quickStartNext — zincir bitince cüzdan sayfası ne yapar', () {
    test('İLK CÜZDAN akışı: her yol sayfayı kapatır', () {
      // Eskiden "atla" ve "işlem ekle" boş bir yönetim sayfasında bırakıyor,
      // kullanıcı onu ayrıca kapatıyordu.
      expect(quickStartNext(WalletQuickStartAction.skip, firstWalletFlow: true),
          QuickStartNext.closePage);
      expect(
          quickStartNext(null, firstWalletFlow: true), QuickStartNext.closePage,
          reason: 'sayfayı aşağı çekip kapatmak da "atla"dır');
      expect(
          quickStartNext(WalletQuickStartAction.addTransaction,
              firstWalletFlow: true),
          QuickStartNext.closePageThenAddTransaction);
      expect(
          quickStartNext(WalletQuickStartAction.importStatement,
              firstWalletFlow: true),
          QuickStartNext.importStatement);
    });

    test('olağan "yeni cüzdan" akışı: sayfa açık kalır (davranış aynı)', () {
      expect(
          quickStartNext(WalletQuickStartAction.skip, firstWalletFlow: false),
          QuickStartNext.stay);
      expect(quickStartNext(null, firstWalletFlow: false), QuickStartNext.stay);
      expect(
          quickStartNext(WalletQuickStartAction.addTransaction,
              firstWalletFlow: false),
          QuickStartNext.addTransactionOnPage);
      expect(
          quickStartNext(WalletQuickStartAction.importStatement,
              firstWalletFlow: false),
          QuickStartNext.importStatement);
    });
  });
}
