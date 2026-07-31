import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/bank_import/data/statement_verification.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/bank_import/presentation/pages/bank_import_review_view.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/intl.dart';

class MockBankImportCubit extends MockCubit<BankImportState>
    implements BankImportCubit {}

CategoryEntity _cat(String id, {bool expense = true}) => CategoryEntity(
      id: id,
      iconName: 'category',
      isExpense: expense,
      sortOrder: 1,
    );

ImportDraft _draft({
  required String description,
  String? categoryId,
  bool duplicate = false,
  bool income = false,
  double amount = 100,
  int day = 5,
}) =>
    ImportDraft(
      date: DateTime(2026, 3, day),
      description: description,
      amount: amount,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      categoryId: categoryId,
      isDuplicate: duplicate,
    );

void main() {
  // Para metni Intl.defaultLocale'e bakar; testte boş bırakılırsa intl onu
  // sessizce sistem locale'ine (genelde en_US) bağlar ve beklentiler
  // makineye göre kayar. Uygulamanın varsayılanına sabitliyoruz.
  setUpAll(() => Intl.defaultLocale = 'tr');

  late MockBankImportCubit cubit;

  setUp(() {
    cubit = MockBankImportCubit();
    when(() => cubit.setAllSelected(any())).thenReturn(null);
    when(() => cubit.toggleDraft(any())).thenReturn(null);
  });

  BankImportReview review({
    required List<ImportDraft> drafts,
    int skippedRows = 0,
    String? walletCurrency = 'TRY',
    String? foreignCurrency,
    bool fromOcr = false,
    bool sourceTruncated = false,
    int sourceUnresolvedCells = 0,
    StatementVerification verification = StatementVerification.none,
  }) =>
      BankImportReview(
        drafts: drafts,
        expenseCategories: [_cat('Market'), _cat('Fatura')],
        incomeCategories: [_cat('Maaş', expense: false)],
        skippedRows: skippedRows,
        walletCurrency: walletCurrency,
        foreignCurrency: foreignCurrency,
        fromOcr: fromOcr,
        sourceTruncated: sourceTruncated,
        sourceUnresolvedCells: sourceUnresolvedCells,
        verification: verification,
      );

  Future<void> pump(WidgetTester tester, BankImportReview state) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: BlocProvider<BankImportCubit>.value(
            value: cubit,
            child: BankImportReviewView(state: state),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('inceleme listesi hatasız çizilir ve satırları gösterir',
      (tester) async {
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'MARKET ALISVERISI', categoryId: 'Market'),
        _draft(description: 'TRENDYOL.COM', day: 6),
      ]),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('MARKET ALISVERISI'), findsOneWidget);
    expect(find.text('TRENDYOL.COM'), findsOneWidget);
  });

  testWidgets('tutarlar hedef cüzdanın para birimiyle gösterilir',
      (tester) async {
    await pump(
      tester,
      review(
        drafts: [_draft(description: 'AMAZON', amount: 250)],
        walletCurrency: 'USD',
      ),
    );

    // ₺ sabit kodluydu; artık cüzdan birimi kullanılıyor.
    expect(find.textContaining(r'$'), findsWidgets);
    expect(find.textContaining('₺'), findsNothing);
  });

  testWidgets('arama açıklamaya göre süzer', (tester) async {
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'MARKET ALISVERISI'),
        _draft(description: 'TRENDYOL.COM', day: 6),
      ]),
    );

    await tester.enterText(find.byType(TextField), 'trendyol');
    await tester.pumpAndSettle();

    expect(find.text('TRENDYOL.COM'), findsOneWidget);
    expect(find.text('MARKET ALISVERISI'), findsNothing);
  });

  testWidgets('"Kategorisiz" filtresi yalnız kategorisi olmayanları gösterir',
      (tester) async {
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'MARKET ALISVERISI', categoryId: 'Market'),
        _draft(description: 'BILINMEYEN ISLEM', day: 6),
      ]),
    );

    await tester.tap(find.textContaining('Kategorisiz'));
    await tester.pumpAndSettle();

    expect(find.text('BILINMEYEN ISLEM'), findsOneWidget);
    expect(find.text('MARKET ALISVERISI'), findsNothing);
  });

  testWidgets('filtreliyken seçim doğru satıra uygulanır (indeks eşlemesi)',
      (tester) async {
    // Kritik: cubit mutasyonları indeks tabanlı; filtre uygulanınca görünür
    // sıradaki 0. satır gerçekte 1. taslak olabilir.
    await pump(
      tester,
      review(drafts: [
        _draft(description: 'MARKET ALISVERISI', categoryId: 'Market'),
        _draft(description: 'BILINMEYEN ISLEM', day: 6),
      ]),
    );

    await tester.tap(find.textContaining('Kategorisiz'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // Görünürde tek satır var ama gerçek indeksi 1 olmalı, 0 değil.
    verify(() => cubit.toggleDraft(1)).called(1);
    verifyNever(() => cubit.toggleDraft(0));
  });

  testWidgets('genel uyarı her zaman görünür, para birimi uyarısı koşullu',
      (tester) async {
    await pump(tester, review(drafts: [_draft(description: 'X')]));
    expect(find.textContaining('otomatik algılandı'), findsOneWidget);
    expect(find.byIcon(Icons.currency_exchange_rounded), findsNothing);

    await pump(
      tester,
      review(drafts: [_draft(description: 'X')], foreignCurrency: 'USD'),
    );
    expect(find.byIcon(Icons.currency_exchange_rounded), findsOneWidget);
  });

  testWidgets('OCR yolundan gelen taslaklar ayrıca uyarılır', (tester) async {
    // Görüntüden okuma en hatalı yol; kullanıcı bunu bilmeli.
    await pump(tester, review(drafts: [_draft(description: 'X')]));
    expect(find.byIcon(Icons.image_search_rounded), findsNothing);

    await pump(
      tester,
      review(drafts: [_draft(description: 'X')], fromOcr: true),
    );
    expect(find.byIcon(Icons.image_search_rounded), findsOneWidget);
    expect(find.textContaining('GÖRÜNTÜDEN'), findsOneWidget);
  });

  testWidgets('kaynak dosya bütünlüğü şüpheliyse uyarılır', (tester) async {
    await pump(
      tester,
      review(
        drafts: [_draft(description: 'X')],
        sourceTruncated: true,
        sourceUnresolvedCells: 3,
      ),
    );
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
  });

  testWidgets('doğrulama geçtiyse yeşil kanıt kartı ve kontrol dökümü',
      (tester) async {
    await pump(
      tester,
      review(
        drafts: [_draft(description: 'MARKET')],
        verification: const StatementVerification(
          status: StatementVerificationStatus.verified,
          checks: [
            StatementCheck(
              kind: StatementCheckKind.balanceChain,
              passed: true,
              detail: '84 / 84',
            ),
            StatementCheck(
              kind: StatementCheckKind.recordCount,
              passed: true,
              detail: '85 / 85',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Aritmetik olarak doğrulandı'), findsOneWidget);
    // Kullanıcı neye güvendiğini görebilmeli: kontrollerin dökümü de basılır.
    expect(find.text('Bakiye zinciri: 84 / 84'), findsOneWidget);
    expect(find.text('Kayıt sayısı: 85 / 85'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('doğrulama tutmazsa kırmızı uyarı ve tutmayan kontrol işaretli',
      (tester) async {
    await pump(
      tester,
      review(
        drafts: [_draft(description: 'MARKET')],
        verification: const StatementVerification(
          status: StatementVerificationStatus.failed,
          checks: [
            StatementCheck(
              kind: StatementCheckKind.balanceChain,
              passed: false,
              detail: '80 / 84',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Doğrulanamadı'), findsOneWidget);
    expect(find.text('Bakiye zinciri: 80 / 84'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('doğrulama yapılamadıysa kart hiç çizilmez', (tester) async {
    await pump(tester, review(drafts: [_draft(description: 'MARKET')]));
    expect(find.text('Aritmetik olarak doğrulandı'), findsNothing);
    expect(find.text('Doğrulanamadı'), findsNothing);
  });

  testWidgets('taslak yoksa boş durum mesajı', (tester) async {
    await pump(tester, review(drafts: const []));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('bulunamadı'), findsOneWidget);
  });
}
