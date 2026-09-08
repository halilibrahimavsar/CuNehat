import 'dart:io';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/receipt_viewer_page.dart';
import 'package:cunehat/features/settings/presentation/page/pin_recovery_page.dart';
import 'package:cunehat/features/settings/presentation/page/privacy_policy_page.dart';
import 'package:cunehat/features/settings/presentation/page/security_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

import '../../support/fake_local_auth_repository.dart';
import '../../support/safe_area_probe.dart';

/// **Edge-to-edge denetimi.**
///
/// `targetSdk 36` ile Android edge-to-edge'i zorunlu kılıyor: uygulama her
/// zaman durum çubuğunun ve gezinme çubuğunun ALTINA çiziyor ve `SystemChrome`
/// ile bundan çıkış yok. Varsayılan test yüzeyinin `padding`'i SIFIR olduğu
/// için bu sınıf hata TÜM testlerden görünmezdi — bu dosyanın tek işi payları
/// geri koymak.
///
/// Ölçülen hata (düzeltmeden önce): gizlilik politikası ve güvenlik ekranında
/// son kart 882dp'de bitiyordu, güvenli sınır 866dp — yani **16dp gezinme
/// çubuğunun altında**. Aynı kalıp 11 sayfada vardı; hepsi
/// `EdgeInsets...plusSystemBottom(context)` ile düzeltildi.
///
/// Burada yalnız az bağımlılıklı sayfalar var; asıl korunan şey KALIBIN
/// kendisi (`SystemBarInsets`) ve onu kullanan üç farklı kaydırıcı biçimi
/// (`ListView`, `SliverPadding`, `AppBar`sız tam ekran).
void main() {
  const insets = DeviceInsets.buttonNav;
  const screen = Size(411, 914);
  final safeBottom = screen.height - insets.bottom; // 866

  setUpAll(() => getIt.allowReassignment = true);
  tearDown(() async => getIt.reset());

  Widget host(Widget page) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: withDeviceInsets(page, insets),
      );

  /// Sayfayı cihaz paylarıyla açar, sonuna kadar kaydırır ve güvenli olmayan
  /// şeride düşen görünür öğeleri döner.
  Future<List<UnsafeHit>> audit(
    WidgetTester tester,
    Widget page, {
    Finder? scrollable,
  }) async {
    await useDevice(tester, size: screen);
    await tester.pumpWidget(host(page));
    await tester.pumpAndSettle();
    if (scrollable != null) {
      await tester.drag(scrollable, const Offset(0, -4000));
      await tester.pumpAndSettle();
    }
    return probeUnsafe(tester, insets: insets, screen: screen);
  }

  void registerLocalAuth() {
    final repo = FakeLocalAuthRepository(
      pinSet: false,
      bioEnabled: false,
      bioAvailable: true,
      backgroundTimeout: 0,
    );
    getIt.registerSingleton<LocalAuthRepository>(repo);
    getIt.registerFactory<LocalAuthSettingsBloc>(
      () => LocalAuthSettingsBloc(repository: repo),
    );
  }

  testWidgets('gizlilik politikası: son satır gezinme çubuğunun üstünde biter',
      (tester) async {
    final hits = await audit(tester, const PrivacyPolicyPage(),
        scrollable: find.byType(ListView));
    expect(hits, isEmpty, reason: reportHits('PrivacyPolicyPage', hits));
    // Sadece "taşmıyor" yetmez: içerik gerçekten sona kadar kaydırılabilmeli.
    // Düzeltmeden önce burası 882dp idi.
    expect(lowestContentBottom(tester, screen), lessThan(safeBottom));
  });

  testWidgets('güvenlik ekranı: son kart gezinme çubuğunun üstünde biter',
      (tester) async {
    registerLocalAuth();
    final hits = await audit(tester, const SecuritySettingsPage(),
        scrollable: find.byType(CustomScrollView));
    expect(hits, isEmpty, reason: reportHits('SecuritySettingsPage', hits));
    expect(lowestContentBottom(tester, screen), lessThan(safeBottom));
  });

  testWidgets('PIN kurtarma: kartlar gezinme çubuğunun altına düşmez',
      (tester) async {
    registerLocalAuth();
    final hits = await audit(tester, const PinRecoveryPage(),
        scrollable: find.byType(ListView));
    expect(hits, isEmpty, reason: reportHits('PinRecoveryPage', hits));
  });

  /// FAB'lı sayfalarda listenin son kartı FAB'ın ALTINDA kalıyordu.
  ///
  /// Scaffold FAB'ı sistem payının üstüne koyar ama gövdeye bunu bildirmez;
  /// dolayısıyla `plusSystemBottom` tek başına yetmez. Burada ölçülen şey
  /// `plusFabClearance`'ın aritmetiği DEĞİL, Flutter'ın FAB'ı gerçekten
  /// nereye koyduğu — o değişirse (SDK yükseltmesi) bu test kırılmalı.
  group('FAB payı', () {
    Future<({Rect fab, Rect lastItem})> layout(
      WidgetTester tester, {
      required Widget fab,
      required double fabHeight,
    }) async {
      final lastKey = GlobalKey();
      await useDevice(tester, size: screen);
      await tester.pumpWidget(host(Scaffold(
        floatingActionButton: fab,
        body: Builder(
          builder: (context) => ListView(
            padding: const EdgeInsets.all(16)
                .plusSystemBottom(context)
                .plusFabClearance(fabHeight: fabHeight),
            children: [
              for (var i = 0; i < 20; i++) const SizedBox(height: 80),
              SizedBox(key: lastKey, height: 80),
            ],
          ),
        ),
      )));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -4000));
      await tester.pumpAndSettle();

      Rect rectOf(Finder f) {
        final ro = tester.renderObject(f) as RenderBox;
        return ro.localToGlobal(Offset.zero) & ro.size;
      }

      return (
        fab: rectOf(find.byType(FloatingActionButton)),
        lastItem: rectOf(find.byKey(lastKey))
      );
    }

    testWidgets('normal FAB (56dp) son öğeyi örtmez', (tester) async {
      final r = await layout(
        tester,
        fab: FloatingActionButton(
            onPressed: () {}, child: const Icon(Icons.add)),
        fabHeight: 56,
      );
      expect(r.lastItem.bottom, lessThanOrEqualTo(r.fab.top),
          reason: 'son öğe ${r.lastItem.bottom}dp\'de bitiyor, '
              'FAB ${r.fab.top}dp\'de başlıyor');
      // FAB'ın kendisi de gezinme çubuğunun üstünde kalmalı.
      expect(r.fab.bottom, lessThanOrEqualTo(safeBottom));
    });

    testWidgets('extended FAB (48dp) son öğeyi örtmez', (tester) async {
      final r = await layout(
        tester,
        fab: FloatingActionButton.extended(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Ekle'),
        ),
        fabHeight: 48,
      );
      expect(r.lastItem.bottom, lessThanOrEqualTo(r.fab.top),
          reason: 'son öğe ${r.lastItem.bottom}dp, FAB ${r.fab.top}dp');
    });
  });

  testWidgets('fiş görüntüleyici: tam ekran görsel kenarlara taşabilir',
      (tester) async {
    // Karşı örnek: burada içeriğin çubuğun altına AKMASI doğru davranış;
    // testin görevi yanlış alarm üretmediğini göstermek.
    final hits =
        await audit(tester, ReceiptViewerPage(imageFile: File('/tmp/yok.png')));
    expect(hits, isEmpty, reason: reportHits('ReceiptViewerPage', hits));
  });
}
