import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/utils/fresh_entry_marker.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/fresh_entrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity tx({
  String wallet = 'w1',
  double amount = 150,
  DateTime? date,
  String tag = 'market',
  TransactionTypeModel type = TransactionTypeModel.expense,
  String? id,
}) =>
    TransactionEntity(
      id: id,
      userId: 'u',
      walletId: wallet,
      title: 'Market',
      tag: tag,
      amount: amount,
      date: date ?? DateTime(2026, 10, 13, 12, 59, 30, 250),
      type: type,
    );

void main() {
  late FreshEntryMarker marker;

  setUp(() => marker = FreshEntryMarker());

  Widget host(TransactionEntity t) => MaterialApp(
        home: Scaffold(
          body: FreshEntrance(
            transaction: t,
            marker: marker,
            child: const SizedBox(key: ValueKey('row'), height: 60, width: 200),
          ),
        ),
      );

  final row = find.byKey(const ValueKey('row'));
  Finder opacityOf() => find.ancestor(of: row, matching: find.byType(Opacity));
  double opacity(WidgetTester tester) =>
      tester.widget<Opacity>(opacityOf().first).opacity;

  testWidgets('yeni kayıt aşağıdan yükselerek belirir', (tester) async {
    marker.mark([tx()]);
    await tester.pumpWidget(host(tx(id: 'a')));

    final start = tester.getTopLeft(row).dy;
    expect(opacity(tester), 0);

    // Kayıt sayfası kapanırken satır görünmez bekler.
    await tester.pump(FreshEntrance.leadIn);
    expect(opacity(tester), 0);
    expect(tester.getTopLeft(row).dy, start);

    await tester.pump(const Duration(milliseconds: 200));
    expect(opacity(tester), inExclusiveRange(0, 1));
    expect(tester.getTopLeft(row).dy, lessThan(start));

    await tester.pumpAndSettle();
    expect(opacity(tester), 1);
    expect(start - tester.getTopLeft(row).dy, closeTo(FreshEntrance.rise, 0.5));
  });

  testWidgets('giriş 650 ms\'de biter (250 bekleme + 400 yükselme)',
      (tester) async {
    marker.mark([tx()]);
    await tester.pumpWidget(host(tx()));

    // Denetleyici TAM süresinde değil, süreyi geçen ilk karede durur.
    await tester.pump(
      FreshEntrance.total + const Duration(milliseconds: 1),
    );
    await tester.pump();

    expect(opacity(tester), 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('yeni olmayan satır olduğu gibi çizilir: sarmalayıcı yok',
      (tester) async {
    await tester.pumpWidget(host(tx()));

    expect(opacityOf(), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('yeniden çizimde giriş tekrar oynamaz', (tester) async {
    marker.mark([tx()]);
    await tester.pumpWidget(host(tx()));
    await tester.pumpAndSettle();

    await tester.pumpWidget(host(tx()));
    await tester.pump();

    expect(opacity(tester), 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets(
      'liste dizinle kurulur: aynı durum nesnesi yeni kaydı devralınca '
      'giriş oynar', (tester) async {
    final old = tx(amount: 10, id: 'old');
    await tester.pumpWidget(host(old));
    expect(opacityOf(), findsNothing);

    // Yeni kayıt üste girdi; bu satır artık onu gösteriyor.
    final fresh = tx(amount: 20);
    marker.mark([fresh]);
    await tester.pumpWidget(host(tx(amount: 20, id: 'new')));

    expect(opacity(tester), 0);
    await tester.pumpAndSettle();
    expect(opacity(tester), 1);
  });

  testWidgets('"animasyonları kaldır" açıkken satır doğrudan yerindedir',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    marker.mark([tx()]);

    await tester.pumpWidget(host(tx()));

    expect(opacityOf(), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
    // İşaret yine de tüketilir: ayar kapatılınca eski kayıt canlanmaz.
    expect(marker.isEmpty, isTrue);
  });
}
