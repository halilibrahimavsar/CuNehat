import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/shared/widgets/app_dialog_surface.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/debt_payment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

class MockDebtBloc extends MockBloc<DebtEvent, DebtState> implements DebtBloc {}

class FakeDebtEvent extends Fake implements DebtEvent {}

void main() {
  late MockDebtBloc mockDebtBloc;

  setUpAll(() {
    registerFallbackValue(FakeDebtEvent());
  });

  setUp(() {
    Intl.defaultLocale = 'tr_TR';
    mockDebtBloc = MockDebtBloc();
    // Diyalog borcu artık bloc'tan CANLI çözüyor (ödeme silme/düzenleme
    // sonrası bayat kopya kalmasın diye); state stub'ı olmadan çöker.
    when(() => mockDebtBloc.state).thenReturn(DebtInitial());
  });

  final testDebt = DebtEntity(
    calcMode: DebtCalcMode.none,
    expectedTotalAmount: 1200.0,
    id: 'debt_1',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Araba Kredisi',
    counterparty: 'Ziraat Bankası',
    type: DebtType.bankLoan,
    principalAmount: 1200.0,
    interestRate: 0.0,
    termMonths: 12,
    startDate: DateTime(2026, 1, 1),
    dueDate: DateTime(2026, 12, 1),
  );

  /// Diyalog kök Navigator'da açılır; bloc'lar uygulamada da MaterialApp'in
  /// ÜSTÜNDE sağlanır (bkz. `AppProviders`), burada da öyle kurulur.
  Widget buildTestableWidget({String currency = 'TRY'}) {
    return BlocProvider<DebtBloc>.value(
      value: mockDebtBloc,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  DebtPaymentDialog.show(context, testDebt, currency: currency),
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('uygulamanın diyalog kabuğunda açılır (cam kabuk değil)',
      (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();

    expect(find.byType(AppDialogSurface), findsOneWidget);
    expect(find.text('Ödeme Yap'), findsOneWidget);
    expect(find.text('Araba Kredisi'), findsOneWidget);
    expect(find.text('Ödemeyi Kaydet'), findsOneWidget);
  });

  testWidgets('geçerli tutarla PayDebtEvent gönderir ve diyaloğu kapatır',
      (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();

    // Tutar alanı formdaki ilk TextFormField (ikincisi "Not").
    await tester.enterText(find.byType(TextFormField).first, '100');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ödemeyi Kaydet'));
    await tester.pumpAndSettle();

    verify(() => mockDebtBloc.add(any(that: isA<PayDebtEvent>()))).called(1);
    expect(find.byType(AppDialogSurface), findsNothing);
  });

  testWidgets('İptal kayıt yapmadan kapatır', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();

    verifyNever(() => mockDebtBloc.add(any(that: isA<PayDebtEvent>())));
    expect(find.byType(AppDialogSurface), findsNothing);
  });

  testWidgets('döviz cüzdanda tüm tutarlar cüzdanın biriminde yazılır',
      (tester) async {
    await tester.pumpWidget(buildTestableWidget(currency: 'USD'));
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();

    // Özet satırları (toplam/ödenen/kalan) ve giriş alanının sonek sembolü.
    expect(find.text('1.200,00 \$'), findsNWidgets(2)); // toplam + kalan
    expect(find.text('0,00 \$'), findsOneWidget); // ödenen
    expect(find.text('\$'), findsOneWidget); // suffixText
    expect(find.textContaining('₺'), findsNothing);
  });

  testWidgets('döviz cüzdanda hızlı ödeme seçenekleri de o birimde yazar',
      (tester) async {
    await tester.pumpWidget(buildTestableWidget(currency: 'EUR'));
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();

    // 1.200 / 12 ay → taksit 100; "1 Taksit" chip'i ve plan satırları €.
    expect(find.textContaining('100,00 €'), findsWidgets);
    expect(find.textContaining('₺'), findsNothing);
  });

  testWidgets(
      'başlangıcı GELECEKTE olan borçta ödeme tarihi seçici çökmeden açılır',
      (tester) async {
    // Regresyon: `firstDate: debt.startDate` gelecekteyken `initialDate`
    // bugüne sabitliydi ve showDatePicker assertion ile düşüyordu:
    // "initialDate 2026-08-06 must be on or after firstDate 2026-09-05".
    final future = DateTime.now().add(const Duration(days: 30));
    final futureDebt = testDebt.copyWith(
      startDate: future,
      dueDate: future.add(const Duration(days: 365)),
    );

    await tester.pumpWidget(BlocProvider<DebtBloc>.value(
      value: mockDebtBloc,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  DebtPaymentDialog.show(context, futureDebt, currency: 'TRY'),
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    final dateField = find.text(l10n.labelOdemeTarihi);
    await tester.ensureVisible(dateField);
    await tester.pumpAndSettle();
    await tester.tap(dateField, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Seçicinin gerçekten AÇILDIĞINI doğrula; tap ıskalasaydı test boş geçerdi.
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
