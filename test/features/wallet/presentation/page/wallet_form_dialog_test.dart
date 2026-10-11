import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

class _MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

/// Cüzdan oluşturma formu — ilk kullanım zincirinin ilk formu.
///
/// Cihazda görüldü: "Oluştur" kaydırılan içeriğin SONUNDAYDI; ad ya da
/// bakiye yazılırken klavyenin altında kalıyor, kullanıcı önce klavyeyi
/// kapatmak zorunda kalıyordu. Sayfa ayrıca durum çubuğunun altına giriyor,
/// düğmenin gölgesi de düz bir dikdörtgen olarak çiziliyordu.
void main() {
  late _MockWalletBloc bloc;

  setUp(() {
    Intl.defaultLocale = 'tr_TR';
    bloc = _MockWalletBloc();
    when(() => bloc.state).thenReturn(const WalletLoadedSt([], null));
  });

  Future<AppLocalizations> openForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<WalletBloc>.value(
        value: bloc,
        child: MaterialApp(
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
                onPressed: () => showCreateEditDialog(
                  context: context,
                  userId: 'u',
                  onSuccess: (_) {},
                  onError: (_) {},
                ),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(const Locale('tr'));
  }

  final save = find.byKey(const ValueKey('wallet-form-save'));

  testWidgets('klavye açıkken "Oluştur" görünür ve dokunulabilir kalır',
      (tester) async {
    final l10n = await openForm(tester);

    // Kısa ekran + açık klavye: forma 440dp kalır; alanların tamamı sığmaz.
    tester.view.physicalSize = const Size(800, 760);
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getRect(save).bottom, lessThanOrEqualTo(760 - 320));
    expect(find.text(l10n.olustur).hitTestable(), findsOneWidget);
    // Yer darken ikincil "İptal" çekilir; kapatma başlıktaki ✕'te durur.
    expect(find.text(l10n.iptal), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('klavye kapalıyken "İptal" de görünür', (tester) async {
    final l10n = await openForm(tester);

    expect(find.text(l10n.iptal), findsOneWidget);
    expect(find.text(l10n.olustur).hitTestable(), findsOneWidget);
  });

  testWidgets('sayfa durum çubuğunun altına girmez', (tester) async {
    await openForm(tester);

    // Çentikli telefon + açık klavye: sayfa ekranı doldurmaya çalışır.
    tester.view.physicalSize = const Size(800, 760);
    tester.view.padding = const FakeViewPadding(top: 40);
    tester.view.viewPadding = const FakeViewPadding(top: 40);
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();

    final top = tester.getTopLeft(find.byIcon(Icons.close_rounded)).dy;
    expect(top, greaterThanOrEqualTo(40));
  });

  testWidgets('düğmenin gölgesi Material\'ın DIŞINDA çizilir', (tester) async {
    await openForm(tester);

    // Gölge Ink'te kalırsa Material sınırına kırpılır ve yuvarlak köşelerin
    // arkasında düz bir dikdörtgen görünür.
    final box = tester.widget<Container>(save);
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.boxShadow, isNotEmpty);
    final ink = tester.widget<Ink>(
      find.descendant(of: save, matching: find.byType(Ink)),
    );
    expect((ink.decoration! as BoxDecoration).boxShadow, isNull);
  });
}
