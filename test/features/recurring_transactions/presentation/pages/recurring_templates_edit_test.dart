import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/services/recent_categories_service.dart';
import 'package:cunehat/core/shared/widgets/row_action_sheet.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/get_all_recurring_templates_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/save_recurring_transaction_usecase.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_event.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_state.dart';
import 'package:cunehat/features/recurring_transactions/presentation/pages/recurring_templates_page.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPendingBloc
    extends MockBloc<PendingRecurringEvent, PendingRecurringState>
    implements PendingRecurringBloc {}

class _MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

class _MockGetAll extends Mock implements GetAllRecurringTemplatesUsecase {}

class _MockSave extends Mock implements SaveRecurringTransactionUsecase {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockWalletCategoryService extends Mock
    implements WalletCategoryService {}

CategoryEntity _cat(String id, String name) => CategoryEntity(
      id: id,
      name: name,
      iconName: 'category',
      isExpense: true,
      sortOrder: 1,
    );

final _wallet = WalletEntity(
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

/// Düzenli işlem şablonu düzenleme ve oluşturma (UX Tur 4 · D2/D3).
///
/// ÖNCE: şablon yalnız duraklatılıp silinebiliyordu; tek kurulma yolu bir
/// işlem eklerken "tekrar" seçmekti. Kirası artan kullanıcı şablonu silip
/// yeni bir kira İŞLEMİ girerek baştan kuruyordu.
void main() {
  late _MockPendingBloc pending;
  late _MockWalletBloc wallets;
  late _MockGetAll getAll;
  late _MockSave save;
  late List<RecurringTransactionEntity> store;

  // 31'inde tekrarlayan kira; vadesi Şubat'ta 28'e kenetlenmiş.
  final rent = RecurringTransactionEntity(
    id: 'r1',
    userId: 'u',
    walletId: 'w1',
    title: 'Kira',
    tag: 'kira',
    amount: 12000,
    type: TransactionTypeModel.expense,
    frequency: RecurringFrequency.monthly,
    nextExecutionDate: DateTime(2099, 2, 28, 9),
    anchorDay: 31,
  );

  setUpAll(() {
    registerFallbackValue(rent);
    registerFallbackValue(const LoadPendingTransactionsEvent());
  });

  setUp(() async {
    Intl.defaultLocale = 'tr_TR';
    getIt.allowReassignment = true;
    SharedPreferences.setMockInitialValues({});
    store = [rent];

    pending = _MockPendingBloc();
    when(() => pending.state).thenReturn(PendingRecurringInitial());
    wallets = _MockWalletBloc();
    when(() => wallets.state).thenReturn(WalletLoadedSt([_wallet], _wallet));

    getAll = _MockGetAll();
    when(() => getAll.call()).thenAnswer((_) async => Right([...store]));
    getIt.registerSingleton<GetAllRecurringTemplatesUsecase>(getAll);

    save = _MockSave();
    when(() => save.call(any())).thenAnswer((invocation) async {
      final t =
          invocation.positionalArguments.single as RecurringTransactionEntity;
      store = [
        for (final e in store)
          if (e.id != t.id) e,
        t,
      ];
      return const Right(null);
    });
    getIt.registerSingleton<SaveRecurringTransactionUsecase>(save);

    final repo = _MockCategoryRepository();
    final cats = [_cat('kira', 'Kira'), _cat('fatura', 'Fatura')];
    when(() => repo.getAllCategories()).thenAnswer((_) async => cats);
    when(() => repo.getCategories(any())).thenAnswer((_) async => cats);
    getIt.registerSingleton<CategoryRepository>(repo);
    final scope = _MockWalletCategoryService();
    when(() => scope.categoriesFor(
          walletId: any(named: 'walletId'),
          isExpense: any(named: 'isExpense'),
          alwaysInclude: any(named: 'alwaysInclude'),
        )).thenAnswer((_) async => cats);
    getIt.registerSingleton<WalletCategoryService>(scope);
    getIt.registerSingleton<RecentCategoriesService>(
      RecentCategoriesService(await SharedPreferences.getInstance()),
    );
  });

  tearDown(() async => getIt.reset());

  Future<AppLocalizations> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<WalletBloc>.value(value: wallets),
          BlocProvider<PendingRecurringBloc>.value(value: pending),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: appMessengerKey,
          locale: const Locale('tr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RecurringTemplatesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(const Locale('tr'));
  }

  RecurringTransactionEntity saved() =>
      verify(() => save.call(captureAny())).captured.single
          as RecurringTransactionEntity;

  String textOf(WidgetTester tester, String key) =>
      tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;

  testWidgets(
      'karta dokun → şablon dolu açılır; tutarı değiştir → aynı şablon '
      'güncellenir, çapa ve vade KORUNUR', (tester) async {
    final l10n = await pumpPage(tester);

    // Sıklık etiketi çeviriden gelir.
    expect(find.text(l10n.monthly), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('template-card-r1')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.sablonuDuzenle), findsOneWidget);
    expect(textOf(tester, 'template-title'), 'Kira');
    expect(textOf(tester, 'template-amount'), '12.000');
    // Tür ve cüzdan kilitli: seçicileri yok.
    expect(find.byKey(const ValueKey('template-type')), findsNothing);
    expect(find.byKey(const ValueKey('template-wallet')), findsNothing);

    await tester.enterText(
        find.byKey(const ValueKey('template-amount')), '15000');
    await tester.tap(find.widgetWithText(FilledButton, l10n.guncelle));
    await tester.pumpAndSettle();

    final t = saved();
    expect(t.id, 'r1');
    expect(t.amount, 15000);
    expect(t.title, 'Kira');
    expect(t.tag, 'kira');
    // Vadeye dokunulmadı: 28 Şub'a kenetlenmiş tarih çapayı 28'e ÇEKMEZ.
    expect(t.anchorDay, 31);
    expect(t.nextExecutionDate, DateTime(2099, 2, 28, 9));
    // Bekleyen liste tazelenir (hatırlatma diyaloğu çıkmadan).
    verify(() => pending.add(
        const LoadPendingTransactionsEvent(suppressNudge: true))).called(1);
    // Liste (kart + aylık yük özeti) yeni tutarı gösterir.
    expect(find.textContaining('15.000'), findsWidgets);
    expect(find.textContaining('12.000'), findsNothing);
  });

  // UX Tur 5 · T1 — satır eylemleri her yerde ⋮'de.
  testWidgets('⋮ menüsü: Düzenle formu açar, Sil onay ister', (tester) async {
    final l10n = await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('template-menu-r1')));
    await tester.pumpAndSettle();
    // Menü uygulamanın ortak eylem sayfası: başlıkta şablonun adı.
    expect(find.byType(RowActionSheet<RowEditDelete>), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('row-action-edit')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.sablonuDuzenle), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, l10n.iptal));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('template-menu-r1')));
    await tester.pumpAndSettle();
    // Silmenin sonucu satırın kendisinde yazar.
    expect(find.text(l10n.sablonuSilAciklama), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('row-action-delete')));
    await tester.pumpAndSettle();
    expect(find.byType(RowActionSheet<RowEditDelete>), findsNothing);
    expect(find.text(l10n.sablonuSil), findsOneWidget);
    verifyNever(() => pending.add(any(that: isA<DeleteTransactionEvent>())));
  });

  testWidgets('düzenlemede vazgeçmek hiçbir şey yazmaz', (tester) async {
    final l10n = await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('template-card-r1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('template-amount')), '1');
    await tester.tap(find.widgetWithText(OutlinedButton, l10n.iptal));
    await tester.pumpAndSettle();

    verifyNever(() => save.call(any()));
  });

  testWidgets('"+" ile işlem yazmadan yeni şablon kurulur', (tester) async {
    final l10n = await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('template-add')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.yeniDuzenliIslem), findsOneWidget);
    expect(find.byKey(const ValueKey('template-type')), findsOneWidget);

    // Eksik formla kaydetme: neyin eksik olduğu yazar, kayıt yok.
    await tester.tap(find.widgetWithText(FilledButton, l10n.kaydet));
    await tester.pumpAndSettle();
    expect(find.text(l10n.baslikGirin), findsOneWidget);
    verifyNever(() => save.call(any()));

    await tester.enterText(
        find.byKey(const ValueKey('template-title')), 'İnternet');
    await tester.enterText(
        find.byKey(const ValueKey('template-amount')), '450');
    await tester.tap(find.byKey(const ValueKey('template-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fatura').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.kaydet));
    await tester.pumpAndSettle();

    final t = saved();
    final now = DateTime.now();
    expect(t.id, isNot('r1'));
    expect(t.title, 'İnternet');
    expect(t.amount, 450);
    expect(t.tag, 'fatura');
    expect(t.walletId, 'w1');
    expect(t.userId, 'u');
    expect(t.type, TransactionTypeModel.expense);
    expect(t.frequency, RecurringFrequency.monthly);
    expect(t.anchorDay, now.day);
    expect(t.isActive, isTrue);
  });

  // Cihazda görüldü: klavye kapalıyken formun İptal/Kaydet düğmeleri sistem
  // gezinme çubuğunun (48dp) ALTINDA kalıyordu — sayfa yalnız klavye payını
  // sayıyordu. Test yüzeyinin sistem payı varsayılan SIFIRDIR; açıkça verilir.
  testWidgets('form düğmeleri gezinme çubuğunun altında kalmaz',
      (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    final l10n = await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('template-add')));
    await tester.pumpAndSettle();

    final save = tester.getRect(find.widgetWithText(FilledButton, l10n.kaydet));
    expect(save.bottom, lessThanOrEqualTo(1600 - 48));
  });

  testWidgets('hiç şablon yokken de "+" var (boş durumdan kurulabilir)',
      (tester) async {
    store = [];
    final l10n = await pumpPage(tester);

    expect(find.text(l10n.henuzDuzenliIslemYok), findsOneWidget);
    expect(find.byKey(const ValueKey('template-add')), findsOneWidget);
  });
}
