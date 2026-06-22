import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/investments/presentation/pages/investment_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInvestmentBloc extends MockBloc<InvestmentEvent, InvestmentState>
    implements InvestmentBloc {}

void main() {
  late MockInvestmentBloc mockInvestmentBloc;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(
      GetInvestmentsEvent(userId: 'user_123', walletId: 'wallet_123'),
    );
  });

  setUp(() {
    mockInvestmentBloc = MockInvestmentBloc();
    getIt.registerSingleton<InvestmentBloc>(mockInvestmentBloc);
  });

  tearDown(() {
    getIt.reset();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      locale: const Locale('tr'),
      home: child,
    );
  }

  final testInvestment1 = InvestmentEntity(
    id: 'inv_1',
    userId: 'user_123',
    walletId: 'wallet_123',
    name: 'Gram Altın',
    amount: 1000.0,
    currentValue: 1250.0,
    type: InvestmentType.gold,
    color: Colors.amber,
    dateAdded: DateTime(2026, 1, 1),
    symbol: 'XAU',
    quantity: 1.0,
  );

  final testInvestment2 = InvestmentEntity(
    id: 'inv_2',
    userId: 'user_123',
    walletId: 'wallet_123',
    name: 'Bireysel Emeklilik',
    amount: 2000.0,
    currentValue: 2000.0,
    type: InvestmentType.custom,
    color: Colors.teal,
    dateAdded: DateTime(2026, 1, 1),
  );

  testWidgets('renders CircularProgressIndicator when loading',
      (WidgetTester tester) async {
    when(() => mockInvestmentBloc.state).thenReturn(InvestmentLoading());

    await tester.pumpWidget(
      buildTestableWidget(
        const InvestmentDetailPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders empty state when there are no investments',
      (WidgetTester tester) async {
    when(() => mockInvestmentBloc.state).thenReturn(
      const InvestmentLoaded([], totalAmount: 0.0),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const InvestmentDetailPage(
          userId: 'user_123',
          walletId: 'wallet_123',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Henüz Yatırım Kaydı Yok'), findsOneWidget);
    expect(
      find.text(
          'Yatırımlarınızı ekledikten sonra detaylı analizler burada görünecektir.'),
      findsOneWidget,
    );
  });

  testWidgets('renders details, summary card, chart and list when loaded',
      (WidgetTester tester) async {
    when(() => mockInvestmentBloc.state).thenReturn(
      InvestmentLoaded(
        [testInvestment1, testInvestment2],
        totalAmount: 3000.0,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(
        const InvestmentDetailPage(
          userId: 'user_123',
          walletId: 'wallet_123',
          showAppBar: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar or Header title is present
    expect(find.text('Birikim Detayı'), findsWidgets);

    // Verify SummaryCard fields
    expect(find.text('TOPLAM PORTFÖY DEĞERİ'), findsOneWidget);
    expect(find.text('₺3.250'), findsOneWidget);
    expect(find.text('₺3.000'), findsOneWidget);

    // Verify Portfolio details list header
    expect(find.text('Portföy Detayı'), findsOneWidget);

    // Verify list items exist
    expect(find.text('Gram Altın'), findsWidgets);
    expect(find.text('Bireysel Emeklilik'), findsWidgets);
  });
}
