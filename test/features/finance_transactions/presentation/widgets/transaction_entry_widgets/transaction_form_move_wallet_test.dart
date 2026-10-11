import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_fields.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../../support/wallet_category_stub.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

WalletEntity _wallet(String id, String name, {String currency = 'TRY'}) =>
    WalletEntity(
      id: id,
      userId: 'u1',
      name: name,
      balance: 1000,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF2196F3',
      iconName: 'wallet',
      createdAt: DateTime(2025, 1, 1),
      openingBalance: 1000,
      currency: currency,
    );

/// Düzenlemede kaydı başka cüzdana taşıma (UX Tur 4 · G3).
///
/// ÖNCE: yanlış cüzdana girilen kayıt taşınamıyordu; silinip doğru cüzdanda
/// baştan giriliyordu.
void main() {
  late _MockWalletBloc wallets;
  late AppLocalizations l10n;

  final cash = _wallet('w1', 'Nakit');
  final bank = _wallet('w2', 'Banka');
  final euro = _wallet('w3', 'Euro', currency: 'EUR');

  final selector = find.byKey(const ValueKey('tx-move-wallet'));

  setUpAll(() async {
    getIt.allowReassignment = true;
    ShowcaseView.register();
    l10n = await AppLocalizations.delegate.load(const Locale('tr'));
  });

  setUp(() {
    final categories = _MockCategoryRepository();
    getIt.registerSingleton<CategoryRepository>(categories);
    registerUncuratedWalletCategories(categories);
    when(() => categories.getCategories(any())).thenAnswer((_) async => [
          const CategoryEntity(
            id: 'Market',
            name: 'Market',
            iconName: 'fastfood',
            isExpense: true,
          ),
        ]);
    wallets = _MockWalletBloc();
    when(() => wallets.state)
        .thenReturn(WalletLoadedSt([cash, bank, euro], cash));
  });

  tearDown(getIt.reset);

  TransactionEntity existing({
    String? installmentGroupId,
    String? linkedRecordId,
  }) =>
      TransactionEntity(
        id: 'tx-1',
        userId: 'u1',
        walletId: 'w1',
        title: 'Haftalık alışveriş',
        tag: 'Market',
        amount: 480.5,
        date: DateTime(2026, 9, 5, 18, 30),
        type: TransactionTypeModel.expense,
        reference: 'BANK-REF-1',
        installmentGroupId: installmentGroupId,
        installmentNo: installmentGroupId == null ? null : 1,
        installmentCount: installmentGroupId == null ? null : 3,
        linkedRecordId: linkedRecordId,
      );

  Future<void> pumpForm(
    WidgetTester tester, {
    TransactionEntity? initial,
    void Function(TransactionEntity)? onSave,
  }) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<WalletBloc>.value(
        value: wallets,
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
            body: Align(
              alignment: Alignment.bottomCenter,
              child: TransactionFormSheet(
                isExpense: true,
                walletId: 'w1',
                userId: 'u1',
                initialTransaction: initial,
                onSave: (t, _) => onSave?.call(t),
                onCancel: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'düzenlemede cüzdan seçilir: yalnız AYNI birimdekiler; kayıt yeni '
      'cüzdana, diğer alanları korunarak yazılır', (tester) async {
    TransactionEntity? saved;
    await pumpForm(tester, initial: existing(), onSave: (t) => saved = t);

    expect(selector, findsOneWidget);
    expect(find.byKey(const ValueKey('pay-w1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pay-w2')), findsOneWidget);
    // Tutar çevrilmez: farklı birimdeki cüzdan seçenek DEĞİLDİR.
    expect(find.byKey(const ValueKey('pay-w3')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('pay-w2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.guncelle));
    // Düğme gönderilirken dönen bir gösterge çizer ve bu test sayfayı
    // kapatmaz: `pumpAndSettle` hiç yerleşmezdi.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(saved, isNotNull);
    expect(saved!.walletId, 'w2');
    expect(saved!.id, 'tx-1');
    expect(saved!.amount, 480.5);
    expect(saved!.tag, 'Market');
    expect(saved!.date, DateTime(2026, 9, 5, 18, 30));
    // Formda olmayan alanlar özgün kayıttan taşınır.
    expect(saved!.reference, 'BANK-REF-1');
  });

  testWidgets('seçiciye dokunulmazsa kayıt yerinde kalır', (tester) async {
    TransactionEntity? saved;
    await pumpForm(tester, initial: existing(), onSave: (t) => saved = t);

    await tester.tap(find.text(l10n.guncelle));
    // Düğme gönderilirken dönen bir gösterge çizer ve bu test sayfayı
    // kapatmaz: `pumpAndSettle` hiç yerleşmezdi.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(saved!.walletId, 'w1');
  });

  testWidgets('taksit ve bağlı satırda cüzdan seçici YOK', (tester) async {
    await pumpForm(tester, initial: existing(installmentGroupId: 'g1'));
    expect(selector, findsNothing);

    await tester.pumpWidget(const SizedBox());
    await pumpForm(tester, initial: existing(linkedRecordId: 'debt-1'));
    expect(selector, findsNothing);
  });

  testWidgets('yeni kayıtta taşıma seçicisi yok (cüzdan zaten etkin olan)',
      (tester) async {
    await pumpForm(tester);
    expect(selector, findsNothing);
  });

  testWidgets('aynı birimde tek cüzdan varsa seçici yok', (tester) async {
    when(() => wallets.state).thenReturn(WalletLoadedSt([cash, euro], cash));
    await pumpForm(tester, initial: existing());
    expect(selector, findsNothing);
  });
}
