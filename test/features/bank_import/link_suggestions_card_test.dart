import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/bank_import/data/link_hint.dart';
import 'package:cunehat/features/bank_import/presentation/widgets/link_suggestions_card.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

class _MockTxRepo extends Mock implements TransactionsRepository {}

TransactionEntity _row(String id, String title, {bool linked = false}) =>
    TransactionEntity(
      id: id,
      userId: 'u',
      walletId: 'w',
      title: title,
      tag: linked ? CashMovementTags.investmentBuy : 'cat-inv',
      amount: 5000,
      date: DateTime(2026, 9, 1),
      type: TransactionTypeModel.expense,
      isSystem: linked,
      linkedRecordId: linked ? 'inv-1' : null,
      adoptedFromTag: linked ? 'cat-inv' : null,
    );

void main() {
  late _MockTxRepo repo;
  late TransactionsChangedNotifier notifier;

  setUp(() {
    Intl.defaultLocale = 'tr_TR';
    getIt.allowReassignment = true;
    repo = _MockTxRepo();
    notifier = TransactionsChangedNotifier();
    getIt.registerSingleton<TransactionsRepository>(repo);
    getIt.registerSingleton<TransactionsChangedNotifier>(notifier);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget app(Widget child) => MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('satır bağlanınca "Bağlandı" olur (defter bildirimiyle)',
      (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    when(() => repo.getTransactionById('a'))
        .thenAnswer((_) async => Right(_row('a', 'MIDAS', linked: true)));
    when(() => repo.getTransactionById('b'))
        .thenAnswer((_) async => Right(_row('b', 'KREDI TAKSIT')));

    await tester.pumpWidget(app(LinkSuggestionsCard(
      currency: 'TRY',
      suggestions: [
        LinkSuggestion(_row('a', 'MIDAS'), LinkHint.investment),
        LinkSuggestion(_row('b', 'KREDI TAKSIT'), LinkHint.debtPayment),
      ],
    )));
    await tester.pumpAndSettle();

    expect(find.text(l10n.bankImportLinkButton), findsNWidgets(2));
    expect(find.textContaining(l10n.linkHintInvestment), findsOneWidget);
    expect(find.textContaining(l10n.linkHintDebtPayment), findsOneWidget);

    notifier.notify(userId: 'u', walletId: 'w');
    await tester.pumpAndSettle();

    expect(find.text(l10n.bankImportLinked), findsOneWidget);
    expect(find.text(l10n.bankImportLinkButton), findsOneWidget);
  });

  testWidgets('geri alınan (silinmiş) satırlar listeden düşer, kart kapanır',
      (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    when(() => repo.getTransactionById(any()))
        .thenAnswer((_) async => const Left(CacheFailure('yok')));

    await tester.pumpWidget(app(LinkSuggestionsCard(
      currency: 'TRY',
      suggestions: [LinkSuggestion(_row('a', 'MIDAS'), LinkHint.investment)],
    )));
    await tester.pumpAndSettle();
    expect(find.text(l10n.bankImportLinkTitle), findsOneWidget);

    notifier.notify(userId: 'u', walletId: 'w');
    await tester.pumpAndSettle();

    expect(find.text(l10n.bankImportLinkTitle), findsNothing);
  });
}
