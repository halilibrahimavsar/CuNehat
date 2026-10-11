import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/shared/widgets/row_action_sheet.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_event.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_state.dart';
import 'package:cunehat/features/recurring_transactions/presentation/widgets/pending_recurring_row.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

class _MockPendingBloc
    extends MockBloc<PendingRecurringEvent, PendingRecurringState>
    implements PendingRecurringBloc {}

class _MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

/// Bekleyen düzenli işlem satırının ⋮ menüsü (UX Tur 5 · T1).
///
/// ÖNCE: düğmenin yanında açılan küçük bir menüydü; işlem ve birikim
/// satırlarının alt sayfasından farklı bir dil.
void main() {
  late _MockPendingBloc pending;
  late _MockWalletBloc wallets;

  final wallet = WalletEntity(
    id: 'w1',
    userId: 'u',
    name: 'Banka',
    balance: 1000,
    debt: 0,
    credit: 0,
    investment: 0,
    colorHex: '0xFF2196F3',
    iconName: 'wallet',
    createdAt: DateTime(2025, 1, 1),
    openingBalance: 1000,
  );

  RecurringTransactionEntity template({required int monthsBehind}) {
    final now = DateTime.now();
    return RecurringTransactionEntity(
      id: 'r1',
      userId: 'u',
      walletId: 'w1',
      title: 'Kira',
      tag: 'kira',
      amount: 12000,
      type: TransactionTypeModel.expense,
      frequency: RecurringFrequency.monthly,
      nextExecutionDate: DateTime(now.year, now.month - monthsBehind, 1, 9),
      anchorDay: 1,
    );
  }

  setUpAll(() {
    registerFallbackValue(const LoadPendingTransactionsEvent());
  });

  setUp(() {
    Intl.defaultLocale = 'tr_TR';
    pending = _MockPendingBloc();
    when(() => pending.state).thenReturn(PendingRecurringInitial());
    wallets = _MockWalletBloc();
    when(() => wallets.state).thenReturn(WalletLoadedSt([wallet], wallet));
  });

  Future<AppLocalizations> pumpRow(
    WidgetTester tester, {
    required int monthsBehind,
    bool busy = false,
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<WalletBloc>.value(value: wallets),
          BlocProvider<PendingRecurringBloc>.value(value: pending),
        ],
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
            body: PendingRecurringRow(
              template: template(monthsBehind: monthsBehind),
              busy: busy,
            ),
          ),
        ),
      ),
    );
    // Meşgul satır ilerleme göstergesi çizer; yerleşmesini bekleme.
    busy ? await tester.pump() : await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(const Locale('tr'));
  }

  // Sayfanın tür parametresi satırın özel enum'u; türden bağımsız ara.
  final sheet = find.byWidgetPredicate((w) => w is RowActionSheet);

  testWidgets('⋮ ortak eylem sayfasını açar; başlıkta şablonun adı',
      (tester) async {
    final l10n = await pumpRow(tester, monthsBehind: 0);

    await tester.tap(find.byType(RowMenuButton));
    await tester.pumpAndSettle();

    expect(sheet, findsOneWidget);
    expect(find.text(l10n.islemiDuzenle), findsOneWidget);
    expect(find.text(l10n.sablonuSil), findsOneWidget);
    // Tek vade bekliyorken "Tümünü onayla" sunulmaz.
    expect(find.text(l10n.tumunuOnayla), findsNothing);
  });

  testWidgets('birden çok vade birikmişse "Tümünü onayla" da çıkar',
      (tester) async {
    final l10n = await pumpRow(tester, monthsBehind: 3);

    await tester.tap(find.byType(RowMenuButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.tumunuOnayla), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('row-action-approveAll')));
    await tester.pumpAndSettle();

    // Toplu onay sessizce çalışmaz: önce onay diyaloğu.
    expect(find.text(l10n.tumunuOnaylaBaslik), findsOneWidget);
    verifyNever(
        () => pending.add(any(that: isA<ApproveAllOccurrencesEvent>())));
  });

  testWidgets('Şablonu Sil → onay ister; onaylanınca silme olayı gider',
      (tester) async {
    final l10n = await pumpRow(tester, monthsBehind: 0);

    await tester.tap(find.byType(RowMenuButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('row-action-delete')));
    await tester.pumpAndSettle();

    verifyNever(() => pending.add(any(that: isA<DeleteTransactionEvent>())));
    await tester.tap(find.text(l10n.sil));
    await tester.pumpAndSettle();
    verify(() => pending.add(any(that: isA<DeleteTransactionEvent>())))
        .called(1);
  });

  testWidgets('işlem sürerken ⋮ kilitli', (tester) async {
    await pumpRow(tester, monthsBehind: 0, busy: true);

    await tester.tap(find.byType(RowMenuButton), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));

    expect(sheet, findsNothing);
  });
}
