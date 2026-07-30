import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// [appMessengerKey]'i bağlayan minimal uygulama kabuğu — gerçek yolun aynısı
/// (`MaterialApp.scaffoldMessengerKey`), böylece testler context'siz çağrıyı
/// üretim davranışıyla doğrular.
Widget _app({ThemeData? theme, Widget? body}) {
  return MaterialApp(
    scaffoldMessengerKey: appMessengerKey,
    theme: theme ??
        ThemeData.light().copyWith(
          extensions: const <ThemeExtension<dynamic>>[AppSurface.light],
        ),
    home: Scaffold(body: body ?? const SizedBox.expand()),
  );
}

/// Snackbar'ı tamamen yerine oturtur.
///
/// `pump(750ms)` YETMEZ: ScaffoldMessenger otomatik kapanma zamanlayıcısını
/// giriş animasyonu bittikten SONRAKİ build'de kurar ve o ana kadar snackbar
/// geçiş sarmalayıcısı içinde olduğu için dokunma da almaz. Testler bu yüzden
/// kareleri sonuna kadar akıtır.
Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle();

void main() {
  group('AppMessenger', () {
    testWidgets('mesajı context olmadan gösterir', (tester) async {
      await tester.pumpWidget(_app());

      AppMessenger.success('kaydedildi');
      await _settle(tester);

      expect(find.text('kaydedildi'), findsOneWidget);
    });

    testWidgets('anahtar bağlı değilken sessizce düşer, fırlatmaz',
        (tester) async {
      // Hiç MaterialApp yok: açılış hata ekranı / saf widget testi durumu.
      expect(() => AppMessenger.error('mesaj'), returnsNormally);
      expect(AppMessenger.error('mesaj'), isNull);
    });

    testWidgets('mesajı gönderen widget ağaçtan düşse de gösterim sürer',
        (tester) async {
      // Regresyon: eski `ScaffoldMessenger.of(context)` yolu, çağıran widget
      // deaktive olduğunda "deactivated widget's ancestor is unsafe" atıyordu.
      await tester.pumpWidget(_app(body: const _EphemeralHost()));
      await tester.tap(find.text('gonder'));
      await _settle(tester);

      // Gönderen element ağaçtan tamamen çıktı; mesaj hâlâ ayakta.
      expect(find.byType(_Ephemeral), findsNothing);
      expect(find.text('async bitti'), findsOneWidget);
    });

    testWidgets('yeni mesaj öncekini devralır (üst üste binmez)',
        (tester) async {
      await tester.pumpWidget(_app());

      AppMessenger.info('birinci');
      await _settle(tester);
      AppMessenger.info('ikinci');
      await _settle(tester);

      expect(find.text('birinci'), findsNothing);
      expect(find.text('ikinci'), findsOneWidget);
    });

    testWidgets('süre tona göre belirlenir ve kendiliğinden kapanır',
        (tester) async {
      await tester.pumpWidget(_app());

      AppMessenger.success('kısa');
      await _settle(tester);
      expect(find.text('kısa'), findsOneWidget);

      await tester.pump(AppMessenger.shortDuration);
      await _settle(tester);
      expect(find.text('kısa'), findsNothing);

      AppMessenger.error('uzun');
      await _settle(tester);
      await tester.pump(AppMessenger.shortDuration);
      // Hata tonu kısa süreyi aşar: hâlâ ekranda.
      expect(find.text('uzun'), findsOneWidget);

      await tester.pump(AppMessenger.longDuration);
      await _settle(tester);
      expect(find.text('uzun'), findsNothing);
    });

    testWidgets('eylem dokunulunca çalışır ve snackbar kapanır',
        (tester) async {
      await tester.pumpWidget(_app());
      var tapped = 0;

      AppMessenger.success(
        'silindi',
        action: AppMessageAction(label: 'Geri al', onPressed: () => tapped++),
      );
      await _settle(tester);

      await tester.tap(find.text('Geri al'));
      await _settle(tester);

      expect(tapped, 1);
      expect(find.text('silindi'), findsNothing);
    });

    testWidgets('eylemli mesaj daha uzun yaşar', (tester) async {
      await tester.pumpWidget(_app());

      AppMessenger.success(
        'silindi',
        action: AppMessageAction(label: 'Geri al', onPressed: () {}),
      );
      await _settle(tester);
      await tester.pump(AppMessenger.longDuration);

      // Uzun süre geçti ama eylem penceresi henüz kapanmadı.
      expect(find.text('Geri al'), findsOneWidget);

      await tester.pump(AppMessenger.actionDuration);
      await _settle(tester);
      expect(find.text('Geri al'), findsNothing);
    });

    testWidgets('hide() açık mesajı kapatır', (tester) async {
      await tester.pumpWidget(_app());

      AppMessenger.warning('dikkat');
      await _settle(tester);
      expect(find.text('dikkat'), findsOneWidget);

      AppMessenger.hide();
      await _settle(tester);
      expect(find.text('dikkat'), findsNothing);
    });

    testWidgets('konum her zaman alt: floating + sabit alt margin',
        (tester) async {
      await tester.pumpWidget(_app());

      AppMessenger.info('altta');
      await _settle(tester);

      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.behavior, SnackBarBehavior.floating);
      // Üst konum hack'i ekran yüksekliği kadar alt boşluk gerektirirdi;
      // margin sabit ve küçük kalmalı.
      expect(snack.margin, const EdgeInsets.fromLTRB(16, 0, 16, 16));
      expect(snack.backgroundColor, Colors.transparent);

      // Ekranın alt yarısında duruyor.
      final rect = tester.getRect(find.text('altta'));
      final screenHeight = tester.getSize(find.byType(MaterialApp)).height;
      expect(rect.center.dy, greaterThan(screenHeight / 2));
    });

    testWidgets('renkler paket sabitleri değil app temasından gelir',
        (tester) async {
      // Ambiyans sızıntısı regresyonu: renk `AppColors.primary` (paket mavisi)
      // gibi sabitlerden değil, tema/paletten türemeli.
      await tester.pumpWidget(_app(
        theme: ThemeData.dark().copyWith(
          extensions: const <ThemeExtension<dynamic>>[AppSurface.dark],
        ),
      ));

      AppMessenger.error('hata');
      await _settle(tester);

      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(SnackBar),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = box.decoration as BoxDecoration;
      // Karanlık temanın AppSurface token'ları gerçekten kullanılıyor.
      expect(decoration.gradient, isNotNull);
      expect(decoration.boxShadow, AppSurface.dark.ambientShadow);

      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.byType(Icon),
        ),
      );
      expect(icon.color, ThemeData.dark().colorScheme.error);
      expect(icon.color, isNot(AppGradients.savings));
    });

    testWidgets('ton ikonu değiştirir (renk körlüğünde ayırt edilebilirlik)',
        (tester) async {
      await tester.pumpWidget(_app());

      for (final entry in <AppMessageTone, IconData>{
        AppMessageTone.success: Icons.check_circle_rounded,
        AppMessageTone.error: Icons.error_rounded,
        AppMessageTone.warning: Icons.warning_amber_rounded,
        AppMessageTone.info: Icons.info_rounded,
      }.entries) {
        AppMessenger.show('mesaj', tone: entry.key);
        await _settle(tester);

        expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.byIcon(entry.value),
          ),
          findsOneWidget,
          reason: '${entry.key} ikonu ${entry.value} olmalı',
        );

        AppMessenger.hide();
        await _settle(tester);
      }
    });
  });
}

/// Gönderen widget'ı ağaçtan gerçekten çıkaran kabuk (yalnız çocuğunu
/// gizlemek yeterli olmazdı: element canlı kalır, deaktivasyon yaşanmaz).
class _EphemeralHost extends StatefulWidget {
  const _EphemeralHost();

  @override
  State<_EphemeralHost> createState() => _EphemeralHostState();
}

class _EphemeralHostState extends State<_EphemeralHost> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.expand();
    return _Ephemeral(onSent: () => setState(() => _show = false));
  }
}

class _Ephemeral extends StatelessWidget {
  final VoidCallback onSent;

  const _Ephemeral({required this.onSent});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        AppMessenger.success('async bitti');
        onSent();
      },
      child: const Text('gonder'),
    );
  }
}
