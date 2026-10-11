import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/debt_repayment_calculator.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/debt_form_preferences.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart';
import 'package:cunehat/core/services/cash_source.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDebtBloc extends Mock implements DebtBloc {}

class MockReceivableBloc extends Mock implements ReceivableBloc {}

class MockOnboardingCoordinator extends Mock implements OnboardingCoordinator {}

void main() {
  late MockDebtBloc mockDebtBloc;
  late MockReceivableBloc mockReceivableBloc;
  late MockOnboardingCoordinator mockOnboardingCoordinator;

  setUpAll(() {
    registerFallbackValue(OnboardingFlow.debtAdd);
    // Showcase scope'u global kayıtla verilir (ShowCaseWidget kullanımdan kalktı).
    ShowcaseView.register(onFinish: () {}, onDismiss: (_) {});
    registerFallbackValue(DebtInitial());
    registerFallbackValue(const GetDebtsEvent('w1'));
    registerFallbackValue(ReceivableInitial());
  });

  setUp(() {
    // Para metinleri locale'e bağlı; sabitlenmezse intl ilk biçimlendirmede
    // sistem locale'ine kilitlenir (bkz. money_format.dart notu).
    Intl.defaultLocale = 'tr_TR';
    mockDebtBloc = MockDebtBloc();
    mockReceivableBloc = MockReceivableBloc();
    mockOnboardingCoordinator = MockOnboardingCoordinator();

    when(() => mockDebtBloc.state).thenReturn(DebtInitial());
    when(() => mockDebtBloc.stream)
        .thenAnswer((_) => const Stream<DebtState>.empty());
    when(() => mockReceivableBloc.stream)
        .thenAnswer((_) => const Stream<ReceivableState>.empty());
    when(() => mockReceivableBloc.state).thenReturn(ReceivableInitial());
    when(() => mockOnboardingCoordinator.isSeen(any())).thenReturn(true);

    if (GetIt.I.isRegistered<OnboardingCoordinator>()) {
      GetIt.I.unregister<OnboardingCoordinator>();
    }
    GetIt.I.registerSingleton<OnboardingCoordinator>(mockOnboardingCoordinator);
  });

  tearDown(() {
    if (GetIt.I.isRegistered<OnboardingCoordinator>()) {
      GetIt.I.unregister<OnboardingCoordinator>();
    }
    if (GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.unregister<SharedPreferences>();
    }
  });

  /// Form artık Kişisel ile açılır; kredi alanlarını ölçen testler türü
  /// kullanıcının yapacağı gibi çipten seçer.
  Future<void> selectType(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  /// "Ne aldın?" seçicisinden bir seçenek işaretler.
  Future<void> chooseImpact(WidgetTester tester, String label) async {
    final option = find.descendant(
      of: find.byKey(const ValueKey('debt-cash-impact')),
      matching: find.text(label),
    );
    await tester.ensureVisible(option);
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester, String label) async {
    // Kaydet form uzunluğu yüzünden görünür alanın altında kalabilir;
    // kaydırılmadan yapılan tap sessizce ıskalar ve test hiçbir şey ölçmez.
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Widget buildTestableWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DebtBloc>.value(value: mockDebtBloc),
        BlocProvider<ReceivableBloc>.value(value: mockReceivableBloc),
      ],
      child: MaterialApp(
        // Metin bazlı beklentiler sabit kalsın diye dil sabitlenir.
        locale: const Locale('tr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('renders AddEntrySheet for debt addition successfully',
      (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      const AddEntrySheet(
        walletId: 'w1',
        userId: 'u1',
        currency: 'TRY',
        initialIsDebt: true,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(AddEntrySheet), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('renders AddEntrySheet for receivable addition successfully',
      (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      const AddEntrySheet(
        walletId: 'w1',
        userId: 'u1',
        currency: 'TRY',
        initialIsDebt: false,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(AddEntrySheet), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  // --------------------------------------------------- Tur adımları kapanı
  // OnboardingTour kapısı turun TÜM hedeflerinin aynı anda render edilmiş
  // olmasını arar (`isTargetRendered`); biri eksikse tur sessizce hiç
  // oynamaz. Vade hapı borç ve alacak dallarında ayrı ayrı kurulduğundan iki
  // mod da doğrulanır.
  for (final isDebt in [true, false]) {
    final mod = isDebt ? 'borç' : 'alacak';
    testWidgets('$mod modunda turun tüm adımları ağaçta', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        AddEntrySheet(
          walletId: 'w1',
          userId: 'u1',
          currency: 'TRY',
          initialIsDebt: isDebt,
        ),
      ));
      await tester.pumpAndSettle();

      final showcase = ShowcaseView.get();
      expect(showcase.isTargetRendered(OnboardingKeys.debtAddForm), isTrue);
      expect(showcase.isTargetRendered(OnboardingKeys.debtAddDueDate), isTrue);
    });
  }

  // ------------------------------------------------- Refactor koruma testleri
  // Aşağıdakiler add_entry/* widget'larına bölünen davranışı sabitler: tutar
  // kartındaki canlı geri ödeme özeti ve tür-özel dinamik alanlar.

  testWidgets('banka kredisinde canlı geri ödeme özeti hesaplanır',
      (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      const AddEntrySheet(
          walletId: 'w1', userId: 'u1', currency: 'TRY', initialIsDebt: true),
    ));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    await selectType(tester, l10n.debtTypeBankLoan);

    // Özet kartı tutar girilmeden "—" gösterir.
    expect(find.text('—'), findsWidgets);

    final amountField = find.byType(TextField).first;
    await tester.enterText(amountField, '12000');
    await tester.pumpAndSettle();

    // Tutar girilince toplam geri ödeme satırı gerçek bir değere döner.
    expect(find.text(l10n.toplamGeriOdeme), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AddEntrySheet),
        matching: find.textContaining('12.000'),
      ),
      findsWidgets,
    );
  });

  testWidgets('kişisel borçta vade/detay alanları gizlenir', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

    await tester.pumpWidget(buildTestableWidget(
      const AddEntrySheet(
          walletId: 'w1', userId: 'u1', currency: 'TRY', initialIsDebt: true),
    ));
    await tester.pumpAndSettle();

    await selectType(tester, l10n.debtTypeBankLoan);

    // bankLoan modunda vade alanı görünür.
    expect(find.text(l10n.vadeAyHint), findsOneWidget);

    await selectType(tester, l10n.debtTypePersonal);

    // personalDebt'te tür-özel alanlar ve geri ödeme özeti kaldırılır.
    expect(find.text(l10n.vadeAyHint), findsNothing);
    expect(find.text(l10n.toplamGeriOdeme), findsNothing);
  });

  testWidgets('alacak formunda borç-özel alanlar hiç gösterilmez',
      (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

    await tester.pumpWidget(buildTestableWidget(
      const AddEntrySheet(
          walletId: 'w1', userId: 'u1', currency: 'TRY', initialIsDebt: false),
    ));
    await tester.pumpAndSettle();

    expect(find.text(l10n.alacakTutari), findsOneWidget);
    expect(find.text(l10n.borcTuruLabel), findsNothing);
    expect(find.text(l10n.toplamGeriOdeme), findsNothing);
  });

  // ------------------------------------------------------- Çoklu para birimi
  // Kayıtta ayrı bir birim alanı yok: birim CÜZDANDAN gelir ve yalnız gösterime
  // akar. Aritmetik (faiz/taksit) birimden bağımsızdır.

  testWidgets('döviz cüzdanda tutar kartı ve geri ödeme özeti o birimde yazar',
      (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

    await tester.pumpWidget(buildTestableWidget(
      const AddEntrySheet(
          walletId: 'w1', userId: 'u1', currency: 'EUR', initialIsDebt: true),
    ));
    await tester.pumpAndSettle();

    // Tutar kartının birim rozeti cüzdanın sembolü (₺ değil).
    expect(find.text('€'), findsOneWidget);
    expect(find.text('₺'), findsNothing);

    await selectType(tester, l10n.debtTypeBankLoan);

    await tester.enterText(find.byType(TextField).first, '12000');
    await tester.enterText(
      find.ancestor(
          of: find.text(l10n.vadeAyHint), matching: find.byType(TextField)),
      '12',
    );
    await tester.pumpAndSettle();

    // 12.000 / 12 ay → taksit 1.000; toplam geri ödeme 12.000, hepsi €.
    expect(find.text('12.000,00 €'), findsOneWidget);
    expect(find.text('1.000,00 €'), findsOneWidget);
  });

  testWidgets(
      'uzun vadede otomatik taksit önerisi kendi doğrulamasına takılmaz',
      (tester) async {
    // Regresyon: tolerans sabit 1 birimdi. Öneri `anapara / vade`yi kuruşa
    // yuvarladığından sapma vadeyle büyür (360 ay → 1,80) ve uygulamanın kendi
    // önerdiği taksit "kredi tutarından küçük" hatasına takılıyordu.
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

    await tester.pumpWidget(buildTestableWidget(
      const AddEntrySheet(
          walletId: 'w1', userId: 'u1', currency: 'TRY', initialIsDebt: true),
    ));
    await tester.pumpAndSettle();
    await selectType(tester, l10n.debtTypeBankLoan);

    // 999.998,64 / 360 = 2.777,774 → öneri 2.777,77 (aşağı yuvarlar).
    await tester.enterText(find.byType(TextField).first, '999998,64');
    await tester.enterText(
      find.ancestor(
          of: find.text(l10n.vadeAyHint), matching: find.byType(TextField)),
      '360',
    );
    await tester.enterText(
      find.ancestor(
          of: find.text(l10n.borcBaslikHint), matching: find.byType(TextField)),
      'Konut Kredisi',
    );
    await tester.enterText(
      find.ancestor(
          of: find.text(l10n.kurumKisiHint), matching: find.byType(TextField)),
      'Banka',
    );
    await tester.pumpAndSettle();

    expect(find.text('2.777,77'), findsOneWidget,
        reason: 'otomatik öneri kuruşa yuvarlanmış olmalı');

    await chooseImpact(tester, l10n.borcNakitSecenekBaslik);
    await tapSave(tester, l10n.kaydet);

    expect(find.text(l10n.aylikTaksitKrediTutarindanKucuk), findsNothing);
    // Doğrulama gerçekten koştu: hata yoksa kayıt bloc'a gider.
    final added = verify(() => mockDebtBloc.add(captureAny()))
        .captured
        .whereType<AddDebtEvent>()
        .single
        .debt;
    expect(added.calcMode, DebtCalcMode.fixedInstallment);
    expect(added.expectedTotalAmount, closeTo(2777.77 * 360, 0.01));
  });

  // ---------------------------------------------------------------------
  // REGRESYON: düzenle → kaydet, kaydın toplamını DEĞİŞTİRMEMELİ
  //
  // Üçünün de kökü aynıydı: hesap yöntemi saklanmıyor, `interestRate`
  // değerinden TAHMİN ediliyordu. Tahmin yanlış olduğunda kaydetme, toplamı
  // yeniden hesaplayıp üzerine yazıyordu. Aşağıdaki üç tutar ölçülmüştür.
  // ---------------------------------------------------------------------
  group('düzenleme kaydı bozmaz', () {
    DebtEntity capturedUpdate() {
      final captured = verify(() => mockDebtBloc.add(captureAny())).captured;
      return captured.whereType<UpdateDebtEvent>().last.debt;
    }

    Future<void> openAndSave(WidgetTester tester, DebtEntity debt) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await tester.pumpWidget(buildTestableWidget(
        AddEntrySheet(
          walletId: 'w1',
          userId: 'u1',
          currency: 'TRY',
          debtToEdit: debt,
        ),
      ));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l10n.guncelle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.guncelle), warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    testWidgets('taksitli borç + basit vade farkı: toplam korunur',
        (tester) async {
      // Ölçülen hata: 12.000 → 10.000 (vade farkı siliniyordu).
      await openAndSave(
        tester,
        DebtEntity(
          id: 'd1',
          userId: 'u1',
          walletId: 'w1',
          title: 'Telefon',
          counterparty: 'Mağaza',
          type: DebtType.installmentDebt,
          calcMode: DebtCalcMode.flatSurcharge,
          principalAmount: 10000,
          interestRate: 20,
          termMonths: 12,
          startDate: DateTime(2026, 1, 1),
          expectedTotalAmount: 12000,
        ),
      );
      final updated = capturedUpdate();
      expect(updated.expectedTotalAmount, 12000);
      expect(updated.calcMode, DebtCalcMode.flatSurcharge);
      expect(updated.interestRate, 20);
    });

    testWidgets('banka kredisi + KKDF/BSMV: vergiler korunur', (tester) async {
      // Ölçülen hata: 117.694,01 → 113.471,52 (vergiler siliniyordu).
      const storedTotal = 117694.01;
      await openAndSave(
        tester,
        DebtEntity(
          id: 'd2',
          userId: 'u1',
          walletId: 'w1',
          title: 'İhtiyaç Kredisi',
          counterparty: 'Banka',
          type: DebtType.bankLoan,
          calcMode: DebtCalcMode.amortizedWithTaxes,
          principalAmount: 100000,
          interestRate: 2,
          termMonths: 12,
          overdueInterestRate: 5,
          startDate: DateTime(2026, 1, 1),
          expectedTotalAmount: storedTotal,
        ),
      );
      final updated = capturedUpdate();
      expect(updated.calcMode, DebtCalcMode.amortizedWithTaxes);
      expect(updated.expectedTotalAmount, closeTo(storedTotal, 0.02));
      expect(updated.overdueInterestRate, 5);
    });

    testWidgets('%0 faizli kredi: mod ve gecikme faizi korunur',
        (tester) async {
      // Ölçülen hata: mod "aylık taksiti biliyorum"a düşüyor, gecikme faizi
      // 7,5 → 0 oluyordu (oran 0 olduğu için mod yanlış tahmin ediliyordu).
      await openAndSave(
        tester,
        DebtEntity(
          id: 'd3',
          userId: 'u1',
          walletId: 'w1',
          title: 'Sıfır Faizli',
          counterparty: 'Banka',
          type: DebtType.bankLoan,
          calcMode: DebtCalcMode.amortized,
          principalAmount: 12000,
          interestRate: 0,
          termMonths: 12,
          overdueInterestRate: 7.5,
          startDate: DateTime(2026, 1, 1),
          expectedTotalAmount: 12000,
        ),
      );
      final updated = capturedUpdate();
      expect(updated.calcMode, DebtCalcMode.amortized);
      expect(updated.expectedTotalAmount, 12000);
      expect(updated.overdueInterestRate, 7.5);
    });
  });

  testWidgets('vade üst sınırı aşılırsa kayıt yapılmaz', (tester) async {
    // Regresyon: sınırsız vadede amortisman formülü sonsuza taşıyor, toplam
    // NaN kaydediliyor ve borç listeden tamamen kayboluyordu.
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    await tester.pumpWidget(buildTestableWidget(
      const AddEntrySheet(
          walletId: 'w1', userId: 'u1', currency: 'TRY', initialIsDebt: true),
    ));
    await tester.pumpAndSettle();
    await selectType(tester, l10n.debtTypeBankLoan);

    await tester.enterText(find.byType(TextField).first, '100000');
    await tester.enterText(
      find.ancestor(
          of: find.text(l10n.vadeAyHint), matching: find.byType(TextField)),
      '36000',
    );
    await tester.enterText(
      find.ancestor(
          of: find.text(l10n.borcBaslikHint), matching: find.byType(TextField)),
      'Kredi',
    );
    await tester.enterText(
      find.ancestor(
          of: find.text(l10n.kurumKisiHint), matching: find.byType(TextField)),
      'Banka',
    );
    await tester.pumpAndSettle();

    await chooseImpact(tester, l10n.borcNakitSecenekBaslik);
    await tapSave(tester, l10n.kaydet);

    expect(find.text(l10n.vadeAraligi(kMaxTermMonths)), findsOneWidget);
    // Doğrulama hatası varken kayıt yazılmaz.
    verifyNever(() => mockDebtBloc.add(any(that: isA<AddDebtEvent>())));
  });

  testWidgets('kişisel borçta vade opsiyoneldir; boş bırakılırsa yazılmaz',
      (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    await tester.pumpWidget(buildTestableWidget(
      const AddEntrySheet(
          walletId: 'w1', userId: 'u1', currency: 'TRY', initialIsDebt: true),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.debtTypePersonal));
    await tester.pumpAndSettle();

    // Opsiyonel vade hapı görünür ve boştur.
    expect(find.text(l10n.vadeOpsiyonelLabel), findsOneWidget);
    expect(find.text(l10n.vadeSecilmedi), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '500');
    await tester.enterText(
      find.ancestor(
          of: find.text(l10n.borcBaslikHint), matching: find.byType(TextField)),
      'Ahmet',
    );
    await tester.enterText(
      find.ancestor(
          of: find.text(l10n.kisiAdiHint), matching: find.byType(TextField)),
      'Ahmet',
    );
    await tester.pumpAndSettle();
    await chooseImpact(tester, l10n.borcNakitSecenekBaslik);
    await tapSave(tester, l10n.kaydet);

    final captured = verify(() => mockDebtBloc.add(captureAny())).captured;
    final added = captured.whereType<AddDebtEvent>().single.debt;
    // Uydurma "başlangıç + 1 ay" vadesi ARTIK YOK → bildirim de kurulmaz.
    expect(added.dueDate, isNull);
    expect(added.calcMode, DebtCalcMode.none);
  });

  testWidgets(
      '"Bağla…" akışından anapara satırı: form satırın tutarıyla açılır, nakit '
      'etkisi SORULMAZ, satır benimsenir', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    final row = TransactionEntity(
      id: 'row-k',
      userId: 'u1',
      walletId: 'w1',
      title: 'KREDI KULLANDIRIM',
      tag: 'cat-diger',
      amount: 500,
      date: DateTime(2026, 9, 2, 10),
      type: TransactionTypeModel.income,
    );
    await tester.pumpWidget(buildTestableWidget(
      AddEntrySheet(
        walletId: 'w1',
        userId: 'u1',
        currency: 'TRY',
        initialPrincipalTransaction: row,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.debtTypePersonal));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '500',
    );
    await tester.enterText(
      find.ancestor(
          of: find.text(l10n.borcBaslikHint), matching: find.byType(TextField)),
      'Kredi',
    );
    await tester.enterText(
      find.ancestor(
          of: find.text(l10n.kisiAdiHint), matching: find.byType(TextField)),
      'Banka',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l10n.kaydet));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.kaydet), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Nakit etki diyaloğu AÇILMADI: cevap belli (anapara o satır).
    expect(find.text(l10n.borcNakitSecenekBaslik), findsNothing);
    final added = verify(() => mockDebtBloc.add(captureAny()))
        .captured
        .whereType<AddDebtEvent>()
        .single;
    expect(added.debt.principalAmount, 500);
    expect(added.debt.startDate, DateTime(2026, 9, 2));
    expect(added.debt.principalToWallet, isTrue);
    expect(added.principalSource, isA<AdoptedCashMovement>());
    expect(
        (added.principalSource as AdoptedCashMovement).transaction.id, 'row-k');
  });

  // ---------------------------------------------------------------------
  // UX Tur 2 (11 Eki 2026) — formun kullanıcıdan istediği emek
  //
  // ÖNCE: form Banka Kredisi ile açılıyordu → ilk ekranda 6 metin alanı
  // (tutar, vade, taksit, gecikme faizi, başlık, kurum) + hesap modu seçici;
  // tür çipleri belirledikleri alanların altındaydı; başlık VE kurum zorunluydu;
  // Kaydet'ten sonra "ne aldın?" diyaloğu çıkıyordu.
  // ---------------------------------------------------------------------
  group('yeni borç formu sade açılır', () {
    const newDebt = AddEntrySheet(
        walletId: 'w1', userId: 'u1', currency: 'TRY', initialIsDebt: true);

    Future<AppLocalizations> pumpNew(WidgetTester tester) async {
      // Uzun yüzey: bölümlerin SIRASI ölçülür, kaydırma değil. Geniş, çünkü
      // test fontu (~1,5× geniş) dar yüzeyde tarih haplarını yapay taşırır.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(buildTestableWidget(newDebt));
      await tester.pumpAndSettle();
      return AppLocalizations.delegate.load(const Locale('tr'));
    }

    Future<SharedPreferences> registerPrefs(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      final prefs = await SharedPreferences.getInstance();
      GetIt.I.registerSingleton<SharedPreferences>(prefs);
      return prefs;
    }

    DebtEntity addedDebt() => verify(() => mockDebtBloc.add(captureAny()))
        .captured
        .whereType<AddDebtEvent>()
        .single
        .debt;

    testWidgets('ilk açılış Kişisel: 3 metin alanı, kredi alanı yok',
        (tester) async {
      final l10n = await pumpNew(tester);

      expect(find.text(l10n.kisiAdiHint), findsOneWidget);
      expect(find.text(l10n.vadeAyHint), findsNothing);
      expect(find.text(l10n.gelismisLabel), findsNothing);
      // Tutar + kişi + (isteğe bağlı) başlık.
      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets(
        'son kaydedilen tür hatırlanır ve bir sonraki form onunla açılır',
        (tester) async {
      final prefs = await registerPrefs({});
      final l10n = await pumpNew(tester);

      await selectType(tester, l10n.debtTypeOther);
      await tester.enterText(find.byType(TextField).first, '1200');
      await tester.enterText(
        find.ancestor(
            of: find.text(l10n.vadeAyHint), matching: find.byType(TextField)),
        '6',
      );
      await tester.enterText(
        find.ancestor(
            of: find.text(l10n.kurumKisiHint),
            matching: find.byType(TextField)),
        'Esnaf',
      );
      await tester.pumpAndSettle();
      await chooseImpact(tester, l10n.borcEtkiUrunKisa);
      await tapSave(tester, l10n.kaydet);

      expect(addedDebt().type, DebtType.otherDebt);
      expect(DebtFormPreferences(prefs).lastType(), DebtType.otherDebt);

      // Yeni bir form: artık Diğer ile açılır (vade alanı hazır).
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(buildTestableWidget(newDebt));
      await tester.pumpAndSettle();
      expect(find.text(l10n.vadeAyHint), findsOneWidget);
    });

    testWidgets('tanınmayan kayıtlı tür Kişisel\'e düşer', (tester) async {
      await registerPrefs({DebtFormPreferences.lastTypeKey: 'silinmisTur'});
      final l10n = await pumpNew(tester);
      expect(find.text(l10n.kisiAdiHint), findsOneWidget);
    });

    testWidgets('düzenlemede kaydın kendi türü, hatırlanan değil',
        (tester) async {
      await registerPrefs({DebtFormPreferences.lastTypeKey: 'personalDebt'});
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await tester.pumpWidget(buildTestableWidget(
        AddEntrySheet(
          walletId: 'w1',
          userId: 'u1',
          currency: 'TRY',
          debtToEdit: DebtEntity(
            id: 'd9',
            userId: 'u1',
            walletId: 'w1',
            title: 'Kredi',
            counterparty: 'Banka',
            type: DebtType.bankLoan,
            calcMode: DebtCalcMode.fixedInstallment,
            principalAmount: 12000,
            interestRate: 0,
            termMonths: 12,
            startDate: DateTime(2026, 1, 1),
            expectedTotalAmount: 12000,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(l10n.vadeAyHint), findsOneWidget);
      // Düzenlemede "ne aldın?" sorulmaz: kuplaj kayıtla kurulmuştur.
      expect(find.byKey(const ValueKey('debt-cash-impact')), findsNothing);
    });

    testWidgets('tür çipleri belirledikleri alanların ÜSTÜNDE', (tester) async {
      final l10n = await pumpNew(tester);
      await selectType(tester, l10n.debtTypeBankLoan);

      final chips = tester.getRect(find.text(l10n.debtTypeBankLoan));
      final term = tester.getRect(find.text(l10n.vadeAyHint));
      final person = tester.getRect(find.text(l10n.kurumKisiHint));
      debugPrint('çipler y=${chips.top} · vade y=${term.top} · '
          'kurum y=${person.top}');
      expect(chips.bottom, lessThan(term.top));
      expect(term.bottom, lessThan(person.top));
    });

    testWidgets('kredide ileri seviye alanlar kapalı "Gelişmiş" bölümünde',
        (tester) async {
      final l10n = await pumpNew(tester);
      await selectType(tester, l10n.debtTypeBankLoan);

      // Görünen: vade + aylık taksit. Jargon kapalı.
      expect(find.text(l10n.vadeAyHint), findsOneWidget);
      expect(find.text(l10n.aylikTaksitHint), findsOneWidget);
      expect(find.text(l10n.gecikmeFaiziYuzdeHint), findsNothing);
      expect(find.text(l10n.faizOraniIle), findsNothing);
      // Kapalıyken içeride ne olduğu yazar.
      expect(find.text(l10n.borcGelismisOzetBanka), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('debt-advanced-toggle')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.gecikmeFaiziYuzdeHint), findsOneWidget);
      expect(find.text(l10n.faizOraniIle), findsOneWidget);
      expect(find.text(l10n.kKDFVeBsmvVergilerini), findsNothing);

      // Faiz moduna geçince vergi anahtarı da açılır, üstteki alan değişir.
      await tester.tap(find.text(l10n.faizOraniIle));
      await tester.pumpAndSettle();
      expect(find.text(l10n.kKDFVeBsmvVergilerini), findsOneWidget);
      expect(find.text(l10n.aylikFaizYuzdeHint), findsOneWidget);
      expect(find.text(l10n.aylikTaksitHint), findsNothing);
    });

    testWidgets(
        'varsayılan dışı ayarı olan kayıt düzenlenirken "Gelişmiş" AÇIK gelir',
        (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      await tester.pumpWidget(buildTestableWidget(
        AddEntrySheet(
          walletId: 'w1',
          userId: 'u1',
          currency: 'TRY',
          debtToEdit: DebtEntity(
            id: 'd8',
            userId: 'u1',
            walletId: 'w1',
            title: 'Kredi',
            counterparty: 'Banka',
            type: DebtType.bankLoan,
            calcMode: DebtCalcMode.fixedInstallment,
            principalAmount: 12000,
            interestRate: 0,
            termMonths: 12,
            overdueInterestRate: 4,
            startDate: DateTime(2026, 1, 1),
            expectedTotalAmount: 12000,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(l10n.gecikmeFaiziYuzdeHint), findsOneWidget);
    });

    testWidgets('başlık isteğe bağlı: boşsa kişi adına düşer', (tester) async {
      final l10n = await pumpNew(tester);

      await tester.enterText(find.byType(TextField).first, '500');
      await tester.enterText(
        find.ancestor(
            of: find.text(l10n.kisiAdiHint), matching: find.byType(TextField)),
        'Ahmet',
      );
      await tester.pumpAndSettle();
      await chooseImpact(tester, l10n.borcNakitSecenekBaslik);
      await tapSave(tester, l10n.kaydet);

      final debt = addedDebt();
      expect(debt.title, 'Ahmet');
      expect(debt.counterparty, 'Ahmet');
    });

    testWidgets('kişi/kurum boşsa kayıt yapılmaz', (tester) async {
      final l10n = await pumpNew(tester);

      await tester.enterText(find.byType(TextField).first, '500');
      await tester.enterText(
        find.ancestor(
            of: find.text(l10n.borcBaslikHint),
            matching: find.byType(TextField)),
        'Yalnız başlık',
      );
      await tester.pumpAndSettle();
      await chooseImpact(tester, l10n.borcNakitSecenekBaslik);
      await tapSave(tester, l10n.kaydet);

      expect(find.text(l10n.kurumKisiGirin), findsOneWidget);
      verifyNever(() => mockDebtBloc.add(any(that: isA<AddDebtEvent>())));
    });

    testWidgets('"ne aldın?" formun içinde ve seçilmeden kaydedilmez',
        (tester) async {
      final l10n = await pumpNew(tester);

      // Soru Kaydet'e basmadan ÖNCE görünür.
      expect(find.text(l10n.borcNakitEtkiBaslik), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '750');
      await tester.enterText(
        find.ancestor(
            of: find.text(l10n.kisiAdiHint), matching: find.byType(TextField)),
        'Ayşe',
      );
      await tester.pumpAndSettle();
      await tapSave(tester, l10n.kaydet);

      // Ön seçim yok: bakiyeyi değiştirecek karar sessizce verilmez.
      expect(find.text(l10n.borcEtkiSecin), findsOneWidget);
      verifyNever(() => mockDebtBloc.add(any(that: isA<AddDebtEvent>())));

      // Seçince sonuç, girilen tutarla yazılır.
      await chooseImpact(tester, l10n.borcNakitSecenekBaslik);
      expect(find.text(l10n.borcEtkiSecin), findsNothing);
      expect(find.text(l10n.borcNakitSecenekGovde('750,00 ₺')), findsOneWidget);

      await tapSave(tester, l10n.kaydet);
      final added = verify(() => mockDebtBloc.add(captureAny()))
          .captured
          .whereType<AddDebtEvent>()
          .single;
      expect(added.debt.principalToWallet, isTrue);
      expect(added.principalSource, isA<NewCashMovement>());
      // Kaydet'ten sonra diyalog YOK.
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('"Ürün / hizmet" seçilirse anapara cüzdana yazılmaz',
        (tester) async {
      final l10n = await pumpNew(tester);

      await tester.enterText(find.byType(TextField).first, '750');
      await tester.enterText(
        find.ancestor(
            of: find.text(l10n.kisiAdiHint), matching: find.byType(TextField)),
        'Ayşe',
      );
      await tester.pumpAndSettle();
      await chooseImpact(tester, l10n.borcEtkiUrunKisa);
      expect(find.text(l10n.borcUrunSecenekGovde), findsOneWidget);
      await tapSave(tester, l10n.kaydet);

      expect(addedDebt().principalToWallet, isFalse);
    });
  });
}
