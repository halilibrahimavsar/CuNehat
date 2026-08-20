import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

class _MockTransactionBloc extends MockBloc<TransactionEvent, TransactionState>
    implements TransactionBloc {}

TransactionWithBalance _item(
  String id,
  DateTime date,
  double amount, {
  bool expense = true,
}) {
  return TransactionWithBalance(
    transaction: TransactionEntity(
      id: id,
      userId: 'u',
      walletId: 'w',
      title: 'İşlem $id',
      tag: 'cat',
      amount: amount,
      date: date,
      type:
          expense ? TransactionTypeModel.expense : TransactionTypeModel.income,
    ),
    balanceAfter: 0,
  );
}

void main() {
  setUpAll(() => Intl.defaultLocale = 'tr');

  late _MockTransactionBloc bloc;

  setUp(() {
    bloc = _MockTransactionBloc();
    when(() => bloc.state).thenReturn(const TransactionLoading());
  });

  Widget wrap(Widget child) {
    return BlocProvider<AmountVisibilityCubit>(
      create: (_) => AmountVisibilityCubit(),
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
          body: BlocProvider<TransactionBloc>.value(value: bloc, child: child),
        ),
      ),
    );
  }

  // Temmuz + Ağustos karışık; dönem yalnız Ağustos'u kapsayacak.
  final transactions = [
    _item('a', DateTime(2026, 8, 10, 12), 250),
    _item('b', DateTime(2026, 8, 12, 12), 100),
    _item('c', DateTime(2026, 7, 20, 12), 9999),
    _item('d', DateTime(2026, 8, 5, 12), 1000, expense: false),
  ];

  Widget calendar({
    DateTimeRange? range,
    ValueChanged<DateTimeRange>? onRangeChanged,
  }) {
    return TransactionCalendarView(
      transactions: transactions,
      range: range ?? monthRangeOf(DateTime(2026, 8, 1)),
      onRangeChanged: onRangeChanged ?? (_) {},
    );
  }

  testWidgets('kendi dönem oku/başlığı YOK (üst çubuk sahibi)', (tester) async {
    await tester.pumpWidget(wrap(calendar()));
    await tester.pumpAndSettle();

    // Dönem gezinme tek yerde olmalı; takvimde ikinci bir ok çifti
    // kullanıcıya iki ayrı zaman ekseni varmış izlenimi veriyordu.
    expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('dönem özeti DÖNEMİ toplar, görünen ızgarayı değil',
      (tester) async {
    await tester.pumpWidget(wrap(calendar()));
    await tester.pumpAndSettle();

    // Ağustos gideri 250 + 100 = 350. Temmuz'daki 9.999 girmemeli.
    expect(find.text('350,00 ₺'), findsWidgets);
    expect(find.textContaining('9.999'), findsNothing);
  });

  testWidgets('dönem dışındaki günler soluklaştırılır', (tester) async {
    // Dönem 10–12 Ağustos; ızgara tüm Ağustos'u gösteriyor ama yalnız üç gün
    // sayılıyor — hangi günlerin sayıldığı hücreye bakınca anlaşılmalı.
    await tester.pumpWidget(wrap(calendar(
      range: DateTimeRange(
        start: DateTime(2026, 8, 10),
        end: DateTime(2026, 8, 12, 23, 59, 59),
      ),
    )));
    await tester.pumpAndSettle();

    final dimmed = tester
        .widgetList<Opacity>(find.byType(Opacity))
        .where((o) => o.opacity < 1)
        .length;
    expect(dimmed, greaterThan(20),
        reason: 'Ağustos\'un 31 gününden 28\'i dönem dışında');
  });

  testWidgets('Hafta kipine geçiş dönemi hafta olarak yazar', (tester) async {
    DateTimeRange? emitted;
    await tester.pumpWidget(wrap(calendar(
      range: monthRangeOf(DateTime(2026, 8, 1)),
      onRangeChanged: (r) => emitted = r,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hafta'));
    await tester.pumpAndSettle();

    expect(emitted, isNotNull);
    expect(periodKindOf(emitted!), PeriodKind.week);
  });

  testWidgets('seçili gün panelinin başlığı ve kartları eşleşir',
      (tester) async {
    await tester.pumpWidget(wrap(calendar(
      range: DateTimeRange(
        start: DateTime(2026, 8, 10),
        end: DateTime(2026, 8, 10, 23, 59, 59),
      ),
    )));
    await tester.pumpAndSettle();

    // Dönem tek gün → odak o gün → alt panel o günün işlemini gösterir.
    expect(find.text('İşlem a'), findsOneWidget);
    expect(find.text('İşlem b'), findsNothing);
  });

  testWidgets('dönem dışarıdan değişince odak oraya kayar', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(wrap(SizedBox(key: key, child: calendar())));
    await tester.pumpAndSettle();

    await tester.pumpWidget(wrap(SizedBox(
      key: key,
      child: calendar(
        range: DateTimeRange(
          start: DateTime(2026, 7, 20),
          end: DateTime(2026, 7, 20, 23, 59, 59),
        ),
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('İşlem c'), findsOneWidget);
    expect(find.text('İşlem a'), findsNothing);
  });

  testWidgets('veri aralığı DIŞINDAKİ döneme odaklanabilir', (tester) async {
    // Takvim sınırları yalnız VERİYE göre kurulursa, veriden çok önceki bir
    // dönem ("geçen yıl") _clamp tarafından geri çekilir ve takvim yanlış aya
    // odaklanır. Odak doğrudan ölçülür: ızgaradaki gün sayıları aylar arası
    // ayırt edici değil.
    final key = GlobalKey();
    await tester.pumpWidget(wrap(SizedBox(key: key, child: calendar())));
    await tester.pumpAndSettle();

    await tester.pumpWidget(wrap(SizedBox(
      key: key,
      child: calendar(range: monthRangeOf(DateTime(2019, 4, 1))),
    )));
    await tester.pumpAndSettle();

    final table = tester.widget<TableCalendar<TransactionWithBalance>>(
      find.byType(TableCalendar<TransactionWithBalance>),
    );
    expect(table.focusedDay.year, 2019);
    expect(table.focusedDay.month, 4);
    expect(tester.takeException(), isNull);
  });
}
