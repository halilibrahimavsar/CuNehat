import 'package:cunehat/core/l10n/app_localizations.dart';
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
}
