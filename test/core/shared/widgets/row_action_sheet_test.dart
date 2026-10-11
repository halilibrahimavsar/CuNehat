import 'dart:io';

import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/shared/widgets/row_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Act { pay, edit, delete }

void main() {
  Widget host(Widget child) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(body: child),
      );

  List<RowAction<_Act>> actions({bool canDelete = true}) => [
        const RowAction(
          value: _Act.pay,
          icon: Icons.payment,
          title: 'Ödeme yap',
          subtitle: 'Taksit ya da ara ödeme',
        ),
        const RowAction(
          value: _Act.edit,
          icon: Icons.edit_rounded,
          title: 'Düzenle',
        ),
        RowAction(
          value: _Act.delete,
          icon: Icons.delete_outline_rounded,
          title: 'Sil',
          subtitle: canDelete ? null : 'Etkin kayıt silinemez',
          destructive: true,
          enabled: canDelete,
        ),
      ];

  Future<void> open(
    WidgetTester tester, {
    required ValueChanged<_Act?> onResult,
    bool canDelete = true,
  }) async {
    await tester.pumpWidget(host(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => onResult(await RowActionSheet.show<_Act>(
            context,
            title: 'Konut Kredisi',
            subtitle: 'Ziraat Bankası',
            icon: Icons.account_balance_wallet,
            accent: Colors.blue,
            actions: actions(canDelete: canDelete),
          )),
          child: const Text('aç'),
        ),
      ),
    ));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
  }

  testWidgets('başlıkta kaydın adı, altında eylemler; seçim değeriyle kapanır',
      (tester) async {
    _Act? result;
    await open(tester, onResult: (v) => result = v);

    expect(find.text('Konut Kredisi'), findsOneWidget);
    expect(find.text('Ziraat Bankası'), findsOneWidget);
    expect(find.text('Taksit ya da ara ödeme'), findsOneWidget);

    // Yıkıcı eylem en altta durur.
    final editY =
        tester.getTopLeft(find.byKey(const ValueKey('row-action-edit'))).dy;
    final deleteY =
        tester.getTopLeft(find.byKey(const ValueKey('row-action-delete'))).dy;
    expect(deleteY, greaterThan(editY));

    await tester.tap(find.byKey(const ValueKey('row-action-edit')));
    await tester.pumpAndSettle();

    expect(result, _Act.edit);
    expect(find.byType(RowActionSheet<_Act>), findsNothing);
  });

  testWidgets('yıkıcı eylem tema hata renginde yazılır', (tester) async {
    await open(tester, onResult: (_) {});

    final context = tester.element(find.byType(RowActionSheet<_Act>));
    final title = tester.widget<Text>(find.text('Sil'));
    expect(title.style?.color, Theme.of(context).colorScheme.error);
  });

  testWidgets('kapalı eylem görünür kalır, nedenini yazar ve seçilemez',
      (tester) async {
    var calls = 0;
    await open(tester, onResult: (_) => calls++, canDelete: false);

    expect(find.text('Etkin kayıt silinemez'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('row-action-delete')));
    await tester.pumpAndSettle();

    // Sayfa açık kaldı, hiçbir sonuç dönmedi.
    expect(find.byType(RowActionSheet<_Act>), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('dar ve kısa ekranda (320×480) taşmadan kaydırılır',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await open(tester, onResult: (_) {});

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('row-action-pay')), findsOneWidget);
  });

  testWidgets('RowActionTarget: karta dokunmak sayfayı açar, seçim geri döner',
      (tester) async {
    _Act? picked;
    await tester.pumpWidget(host(
      RowActionTarget<_Act>(
        title: 'Konut Kredisi',
        icon: Icons.account_balance_wallet,
        accent: Colors.blue,
        actions: actions(),
        onSelected: (v) => picked = v,
        child: const SizedBox(
          width: 200,
          height: 80,
          child: ColoredBox(color: Colors.white, child: Text('kart')),
        ),
      ),
    ));

    await tester.tap(find.text('kart'));
    await tester.pumpAndSettle();
    expect(find.byType(RowActionSheet<_Act>), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('row-action-pay')));
    await tester.pumpAndSettle();
    expect(picked, _Act.pay);
  });

  testWidgets('RowActionTarget: vazgeçince onSelected çağrılmaz',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(
      RowActionTarget<_Act>(
        title: 'Konut Kredisi',
        icon: Icons.account_balance_wallet,
        accent: Colors.blue,
        actions: actions(),
        onSelected: (_) => calls++,
        child: const SizedBox(width: 200, height: 80, child: Text('kart')),
      ),
    ));

    await tester.tap(find.text('kart'));
    await tester.pumpAndSettle();
    // Sayfanın dışına (perdeye) dokun.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(RowActionSheet<_Act>), findsNothing);
    expect(calls, 0);
  });

  testWidgets('RowMenuButton: 44dp yüksekliğinde dokunma alanı ve ipucu',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(
      Center(child: RowMenuButton(onPressed: () => taps++)),
    ));

    final size = tester.getSize(find.byType(RowMenuButton));
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, greaterThanOrEqualTo(40));
    expect(find.byTooltip('Seçenekler'), findsOneWidget);

    await tester.tap(find.byType(RowMenuButton));
    expect(taps, 1);
  });

  // Bekçi: satır eylemleri tek dilde kalsın. Yeni bir satır menüsü
  // PopupMenuButton ile yazılırsa bu test düşer; doğru yol RowActionSheet.
  test('lib/ içinde izinli olanlar dışında açılır menü yok', () {
    // Satır menüsü OLMAYAN iki yer: ekstre inceleme ekranının araç çubuğu
    // taşma menüsü ve ödeme diyaloğunun İÇİNDEKİ ödeme satırı (diyalogun
    // üstüne alt sayfa açmak iki katmanlı bir modal yaratırdı).
    const allowed = {
      'lib/features/bank_import/presentation/pages/bank_import_review_view.dart',
      'lib/features/debt_and_receivable/presentation/widgets/debt_payment_dialog.dart',
    };
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (allowed.contains(path)) continue;
      final source = entity.readAsStringSync();
      if (source.contains('PopupMenuButton<') ||
          source.contains('PopupMenuButton(') ||
          source.contains('showMenu(') ||
          source.contains('showMenu<')) {
        offenders.add(path);
      }
    }
    expect(offenders, isEmpty,
        reason: 'Satır eylemleri RowActionSheet ile açılmalı.');
  });
}
