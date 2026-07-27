import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockDebtBloc extends Mock implements DebtBloc {}
class MockReceivableBloc extends Mock implements ReceivableBloc {}
class MockOnboardingCoordinator extends Mock implements OnboardingCoordinator {}

void main() {
  late MockDebtBloc mockDebtBloc;
  late MockReceivableBloc mockReceivableBloc;
  late MockOnboardingCoordinator mockOnboardingCoordinator;

  setUpAll(() {
    registerFallbackValue(OnboardingFlow.debtAdd);
    registerFallbackValue(DebtInitial());
    registerFallbackValue(ReceivableInitial());
  });

  setUp(() {
    mockDebtBloc = MockDebtBloc();
    mockReceivableBloc = MockReceivableBloc();
    mockOnboardingCoordinator = MockOnboardingCoordinator();

    when(() => mockDebtBloc.state).thenReturn(DebtInitial());
    when(() => mockReceivableBloc.state).thenReturn(ReceivableInitial());

    when(() => mockOnboardingCoordinator.registerKeys(any(), any())).thenReturn(null);
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
  });


  Widget buildTestableWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DebtBloc>.value(value: mockDebtBloc),
        BlocProvider<ReceivableBloc>.value(value: mockReceivableBloc),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShowCaseWidget(
          builder: (context) => Scaffold(body: child),
        ),
      ),
    );
  }

  testWidgets('renders AddEntrySheet for debt addition successfully', (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      const AddEntrySheet(
        walletId: 'w1',
        userId: 'u1',
        initialIsDebt: true,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(AddEntrySheet), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('renders AddEntrySheet for receivable addition successfully', (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      const AddEntrySheet(
        walletId: 'w1',
        userId: 'u1',
        initialIsDebt: false,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(AddEntrySheet), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });
}
