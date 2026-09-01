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

  group('ReportCompareRamp', () {
    // Bu hex'ler GÖZLE seçilmedi: kartın gerçek zeminine (light #DCE9FD /
    // dark #213B69) karşı sıralı rampa kapısından — tek hue, monoton
    // açıklık, komşu ΔL >= 0.06, yüzeye en yakın uç >= 2:1 — geçirilerek
    // OKLCH'de üretildi. Test bilerek hex'leri sabitliyor: birileri
    // "daha güzel" bir yeşil koyduğunda kapı sessizce delinmesin.
    test('light rampa doğrulanmış adımları taşır', () {
      expect(
        ReportCompareRamp.of(isExpense: false, brightness: Brightness.light),
        const [
          Color(0xFF215E2E),
          Color(0xFF2A733A),
          Color(0xFF338846),
          Color(0xFF3D9F52),
          Color(0xFF47B55F),
        ],
      );
      expect(
        ReportCompareRamp.of(isExpense: true, brightness: Brightness.light),
        const [
          Color(0xFF8D2525),
          Color(0xFFAA2E2F),
          Color(0xFFC93839),
          Color(0xFFE94344),
          Color(0xFFEE6E67),
        ],
      );
    });

    test('dark rampa light\'ın çevirisi DEĞİL, kendi adımlarını taşır', () {
      final lightIncome =
          ReportCompareRamp.of(isExpense: false, brightness: Brightness.light);
      final darkIncome =
          ReportCompareRamp.of(isExpense: false, brightness: Brightness.dark);

      expect(darkIncome, isNot(equals(lightIncome)));
      expect(darkIncome, isNot(equals(lightIncome.reversed.toList())));
      expect(
        darkIncome,
        const [
          Color(0xFF59DF76),
          Color(0xFF4FC86A),
          Color(0xFF45B25D),
          Color(0xFF3C9D51),
          Color(0xFF338745),
        ],
      );
      expect(
        ReportCompareRamp.of(isExpense: true, brightness: Brightness.dark),
        const [
          Color(0xFFF3A9A3),
          Color(0xFFF08B83),
          Color(0xFFED6862),
          Color(0xFFE64243),
          Color(0xFFC83839),
        ],
      );
    });

    test('maxSlices rampa adım sayısıyla birebir', () {
      for (final brightness in Brightness.values) {
        for (final isExpense in [true, false]) {
          expect(
            ReportCompareRamp.of(isExpense: isExpense, brightness: brightness)
                .length,
            ReportCompareRamp.maxSlices,
          );
        }
      }
    });
  });

  group('ReportCategoryDataBuilder.buildRanked', () {
    late ReportCategoryDataBuilder builder;

    setUp(() {
      builder = ReportCategoryDataBuilder(
        range: DateTimeRange(
          start: DateTime(2026, 7, 1),
          end: DateTime(2026, 7, 31),
        ),
        budgets: const [],
        otherCategoryLabel: 'Diğer',
      );
    });

    List<CategoryData> full(Map<String, double> amounts) => [
          for (final e in amounts.entries)
            CategoryData(e.key, e.value, const [], Colors.grey),
        ];

    List<CategoryData> ranked(Map<String, double> amounts) =>
        builder.buildRanked(full(amounts),
            isExpense: true, brightness: Brightness.light);

    test('boş kırılım boş liste döner', () {
      expect(
          builder.buildRanked(const [],
              isExpense: true, brightness: Brightness.light),
          isEmpty);
    });

    test('maxSlices\'i aşan kategoriler "Diğer"de toplanır', () {
      final slices = ranked({
        'A': 500,
        'B': 400,
        'C': 300,
        'D': 200,
        'E': 100,
        'F': 90,
        'G': 80,
      });

      expect(slices.length, ReportCompareRamp.maxSlices);
      // Kova E+F+G = 270 taşır, yani D'den (200) BÜYÜKTÜR ve sıralamada
      // onun önüne geçer. Rampa sıralı bir kodlama olduğu için sıranın
      // gerçek olması şart (bkz. aşağıdaki regresyon testi).
      expect(slices.map((s) => s.name), ['A', 'B', 'C', 'Diğer', 'D']);
      expect(slices[3].isOther, isTrue);
      // Toplam KORUNUR: gruplama tutarı değiştirmez.
      expect(slices.fold<double>(0, (sum, s) => sum + s.totalAmount), 1670);
    });

    test('REGRESYON: "Diğer" kovası tutarına göre sıralanır, sona itilmez',
        () {
      // Gerçek bir ayda ölçüldü: Kira %54, Market %27, Sağlık %5, Fatura %5
      // tutuluyor, kova %9 çıkıyordu — yani 3. büyük kalem "en küçük" rampa
      // adımını (en soluk rengi) alıyor ve en sonda çiziliyordu.
      final slices = ranked({
        'Kira': 24000,
        'Market': 12180,
        'Saglik': 2350,
        'Fatura': 2120,
        'Giyim': 1890,
        'Ulasim': 1440,
        'Eglence': 640,
      });

      final other = slices.firstWhere((s) => s.isOther);
      final otherIndex = slices.indexOf(other);
      expect(other.totalAmount, 1890 + 1440 + 640);
      // Kovadan SONRA gelen her kalem ondan küçük olmalı.
      for (final s in slices.skip(otherIndex + 1)) {
        expect(s.totalAmount, lessThanOrEqualTo(other.totalAmount));
      }
      // Renk sırayı izler: kova kendi rank'ının adımını alır.
      final ramp =
          ReportCompareRamp.of(isExpense: true, brightness: Brightness.light);
      expect(other.color, ramp[otherIndex]);
    });

    test('payı %3\'ün altındakiler sayı tavanına ulaşılmasa da kovaya iner',
        () {
      // 2px boşluklu yığılmış çubukta %3 altı telefonda ~9dp'den ince kalır.
      final slices = ranked({'A': 1000, 'B': 10, 'C': 10});

      expect(slices.length, 2);
      expect(slices.first.name, 'A');
      expect(slices.last.isOther, isTrue);
      expect(slices.last.totalAmount, 20);
    });

    test('kovaya TEK kategori düşerse kova kurulmaz, adı korunur', () {
      final slices = ranked({'A': 1000, 'B': 10});

      expect(slices.length, 2);
      expect(slices.map((s) => s.name), ['A', 'B']);
      expect(slices.every((s) => !s.isOther), isTrue);
    });

    test('renk rank sırasını izler — rampa adımları sırayla dağıtılır', () {
      final slices = ranked({'A': 500, 'B': 400, 'C': 300});
      final ramp =
          ReportCompareRamp.of(isExpense: true, brightness: Brightness.light);

      expect(slices.map((s) => s.color), [ramp[0], ramp[1], ramp[2]]);
    });

    test('gelir ve gider farklı rampalardan renk alır', () {
      final data = full({'A': 100});
      final income = builder.buildRanked(data,
          isExpense: false, brightness: Brightness.light);
      final expense = builder.buildRanked(data,
          isExpense: true, brightness: Brightness.light);

      expect(
          income.single.color,
          ReportCompareRamp.of(isExpense: false, brightness: Brightness.light)
              .first);
      expect(
          expense.single.color,
          ReportCompareRamp.of(isExpense: true, brightness: Brightness.light)
              .first);
      expect(income.single.color, isNot(equals(expense.single.color)));
    });

    test('kovanın işlemleri korunur — detay sayfası onları listeler', () {
      final tx = TransactionEntity(
        id: 'tx_1',
        userId: 'u',
        walletId: 'w',
        title: 'Küçük',
        tag: 'B',
        amount: 10,
        date: DateTime(2026, 7, 15),
        type: TransactionTypeModel.expense,
      );
      final slices = builder.buildRanked(
        [
          const CategoryData('A', 1000, [], Colors.grey),
          CategoryData('B', 10, [tx], Colors.grey),
          const CategoryData('C', 10, [], Colors.grey),
        ],
        isExpense: true,
        brightness: Brightness.light,
      );

      expect(slices.last.isOther, isTrue);
      expect(slices.last.transactions, contains(tx));
    });
  });
}
