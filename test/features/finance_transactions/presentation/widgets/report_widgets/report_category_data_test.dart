import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BuildContext ctx;

  Widget buildTestableWidget() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr'), Locale('en')],
      locale: const Locale('tr'),
      home: Builder(builder: (context) {
        ctx = context;
        return const SizedBox.shrink();
      }),
    );
  }

  group('CategoryData.labelIn', () {
    // REGRESYON: sentetik "Diğer" kovasının `name`'i bir kategori id'si DEĞİL,
    // çağıran tarafından zaten l10n'a çevrilmiş bir ETİKETTİR. tag→ad
    // haritasından geçirilince, kullanıcının GERÇEK "Diğer" kategorisi
    // yeniden adlandırılmışsa kova onun yeni adını alıyor ve yan yana duran
    // iki dilim ayırt edilemez hâle geliyordu. Eşleştirme isimle değil
    // `isOther` bayrağıyla yapılır.

    testWidgets(
        'sentetik kova, aynı isimli gerçek kategorinin yeniden '
        'adlandırmasını ALMAZ', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      const labels = {'Diğer': 'Karışık'};
      const bucket =
          CategoryData('Diğer', 100, [], Colors.blueGrey, isOther: true);
      const realCategory = CategoryData('Diğer', 50, [], Colors.red);

      expect(bucket.labelIn(ctx, labels), 'Diğer');
      expect(realCategory.labelIn(ctx, labels), 'Karışık');
    });

    testWidgets('normal kategori haritadaki yeniden adlandırmayı kullanır',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      const yemek = CategoryData('Yemek', 250, [], Colors.orange);
      expect(yemek.labelIn(ctx, const {'Yemek': 'Restoran'}), 'Restoran');
    });

    testWidgets('haritada olmayan tag l10n\'a düşer', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // Silinmiş kategoriden kalan / sistem etiketi: harita bilmiyor.
      const kira = CategoryData('Kira', 250, [], Colors.orange);
      expect(kira.labelIn(ctx, const {}), isNotEmpty);
    });
  });

  group('hiyerarşi: iniş yolu, "Diğer" kırılımı, odak süzgeci', () {
    final range = DateTimeRange(
      start: DateTime(2026, 7, 1),
      end: DateTime(2026, 7, 31),
    );
    TransactionEntity tx(String id, String tag, double amount,
            {DateTime? date, bool income = false}) =>
        TransactionEntity(
          id: id,
          userId: 'u',
          walletId: 'w',
          title: id,
          tag: tag,
          amount: amount,
          date: date ?? DateTime(2026, 7, 10),
          type: income
              ? TransactionTypeModel.income
              : TransactionTypeModel.expense,
        );
    const roots = {
      'fatura': 'fatura',
      'elektrik': 'fatura',
      'su': 'fatura',
      'kira': 'kira',
      'kitap': 'hobi',
      'hobi': 'hobi',
      'kahve': 'kahve',
    };
    final builder = ReportCategoryDataBuilder(
      range: range,
      budgets: const [],
      otherCategoryLabel: 'Diğer',
      rootIndex: roots,
      includeSystemMovements: false,
    );
    // Hobi (kitap alt kategorisiyle) ve Kahve toplamın %3'ünün altında →
    // "Diğer" (tek kalem düşseydi kova kurulmazdı).
    final ledger = [
      tx('e', 'elektrik', 300),
      tx('s', 'su', 100),
      tx('f', 'fatura', 50),
      tx('k', 'kira', 5000),
      tx('b', 'kitap', 40),
      tx('h', 'hobi', 10),
      tx('c', 'kahve', 30),
      tx('maas', 'kira', 9999, income: true),
    ];
    final full = builder.buildFull(ledger, isExpense: true);
    final pie = builder.buildPie(full);

    test('kovaya TEK kalem düşerse kova kurulmaz, kalem adıyla kalır', () {
      final single = builder.buildPie(builder.buildFull(
          ledger.where((t) => t.tag != 'kahve').toList(),
          isExpense: true));
      expect(single.any((c) => c.isOther), isFalse);
      expect(single.map((c) => c.name), contains('hobi'));
    });

    test('"Diğer" kovası katladığı kökleri çocuk olarak TAŞIR (inilebilir)',
        () {
      final other = pie.firstWhere((c) => c.isOther);
      expect(other.canDrill, isTrue);
      expect(other.children.map((c) => c.name), ['hobi', 'kahve']);
      // Katlanan kökün kendi alt kırılımı da korunur.
      expect(other.children.first.children.map((c) => c.name),
          containsAll(['kitap', 'hobi']));
    });

    test('resolvePath yolu iner, bulunamayan adımda DURUR', () {
      final fatura = pie.firstWhere((c) => c.name == 'fatura');
      expect(
        ReportCategoryDataBuilder.resolvePath(pie, [fatura.step])
            .map((n) => n.name),
        ['fatura'],
      );
      final other = pie.firstWhere((c) => c.isOther);
      final hobi = other.children.first;
      expect(
        ReportCategoryDataBuilder.resolvePath(pie, [other.step, hobi.step])
            .map((n) => n.name),
        ['Diğer', 'hobi'],
      );
      // Başka dönemde "fatura" yoksa yol boş seviyeye inmez.
      expect(
        ReportCategoryDataBuilder.resolvePath(
            pie, [(name: 'yok', isOther: false, isDirect: false)]),
        isEmpty,
      );
      // Yaprak (çocuksuz kök) bir seviye değildir.
      final kira = pie.firstWhere((c) => c.name == 'kira');
      expect(ReportCategoryDataBuilder.resolvePath(pie, [kira.step]), isEmpty);
    });

    test('focusFilter düğümün tutarını BİREBİR seçer (kök/çocuk/doğrudan/Diğer)',
        () {
      double sumFor(CategoryData node) => ledger
          .where(builder.focusFilter(node, isExpense: true))
          .fold(0.0, (s, t) => s + t.amount);

      final fatura = full.firstWhere((c) => c.name == 'fatura');
      expect(sumFor(fatura), fatura.totalAmount);
      for (final child in fatura.children) {
        expect(sumFor(child), child.totalAmount, reason: child.name);
      }
      final other = pie.firstWhere((c) => c.isOther);
      expect(sumFor(other), other.totalAmount);
      // Gelir tarafındaki aynı etiketli kayıt gider odağına girmez.
      final kira = full.firstWhere((c) => c.name == 'kira');
      expect(sumFor(kira), 5000);
    });

    test('withPreviousAmounts alt kategorilere de önceki tutarı iliştirir', () {
      final previous = builder.buildFull([
        tx('e0', 'elektrik', 200, date: DateTime(2026, 6, 10)),
        tx('f0', 'fatura', 80, date: DateTime(2026, 6, 10)),
      ], isExpense: true);
      final withPrev = builder.withPreviousAmounts(full, previous);
      final fatura = withPrev.firstWhere((c) => c.name == 'fatura');
      final elektrik = fatura.children.firstWhere((c) => c.name == 'elektrik');
      final direct = fatura.children.firstWhere((c) => c.isDirect);
      expect(elektrik.changePercent, closeTo(50, 0.001)); // 200 → 300
      expect(direct.previousAmount, 80);
      expect(
          fatura.children.firstWhere((c) => c.name == 'su').previousAmount, 0);
    });
  });

  group('budgetProgressFor — aylık limit, aylık pencere', () {
    // Limit AYLIKTIR. Aralık tam bir ay değilken limit döneme orantılanır
    // (gün / 30,4375): "Bu Yıl"da 12 ayın harcaması 1 aylık limite
    // bölünüp "%340 aşıldı" denen eski hata böylece dönmez, haftalık bakan
    // kullanıcı da bütçesini görür.
    ReportCategoryDataBuilder builderFor(DateTimeRange range) =>
        ReportCategoryDataBuilder(
          range: range,
          budgets: const [
            BudgetEntity(walletId: 'w', categoryId: 'm', limitAmount: 1000),
          ],
          otherCategoryLabel: 'Diğer',
          includeSystemMovements: false,
        );

    test('aralık bir takvim ayıyken oran ÜRETİLİR', () {
      final progress = builderFor(DateTimeRange(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 30),
      )).budgetProgressFor('m', 500);

      expect(progress, isNotNull);
      expect(progress!.progress, 0.5);
      expect(progress.limit, 1000);
      expect(progress.isExceeded, isFalse);
    });

    test('yıl aralığında limit 12 aya ORANTILANIR (%340 hatası dönmez)', () {
      // 2026 = 365 gün → 1000 × 365 / 30,4375 ≈ 11.992 ₺. 12.000 ₺ harcama
      // limitin yaklaşık tamamı; eski hata "1 aylık limitin %1200'ü" derdi.
      final progress = builderFor(DateTimeRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 12, 31),
      )).budgetProgressFor('m', 11000);

      expect(progress, isNotNull);
      expect(progress!.limit, closeTo(1000 * 365 / 30.4375, 0.01));
      expect(progress.isExceeded, isFalse);
    });

    test('haftalık pencerede limit 7 güne orantılanır', () {
      final progress = builderFor(DateTimeRange(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 7),
      )).budgetProgressFor('m', 300);

      expect(progress, isNotNull);
      expect(progress!.limit, closeTo(1000 * 7 / 30.4375, 0.01));
      expect(progress.isExceeded, isTrue); // 300 > ~230
      // Çubuk kırpılır, ETİKET kırpılmaz (rapor "%100", Bütçe "%130"
      // diyordu).
      expect(progress.progress, 1.0);
      expect(progress.ratio, closeTo(300 / (1000 * 7 / 30.4375), 0.0001));
    });
  });
}
