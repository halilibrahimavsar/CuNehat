import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/core/services/recent_categories_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockCategoryRepository repository;

  CategoryEntity cat(
    String id,
    String name, {
    String? parentId,
    int sortOrder = 0,
  }) =>
      CategoryEntity(
        id: id,
        name: name,
        iconName: 'category',
        isExpense: true,
        parentId: parentId,
        sortOrder: sortOrder,
      );

  // Ölçülen gerçek şekle yakın kurgu: çocuklu kökler + çocuksuz bir kök, ve
  // İKİ farklı kök altında AYNI adlı alt kategori ("Su") — arama sonucunda
  // kırıntının neden zorunlu olduğunu bu ikili kanıtlar.
  final fatura = cat('r1', 'Fatura', sortOrder: 0);
  final elektrik = cat('c1', 'Elektrik', parentId: 'r1', sortOrder: 0);
  final internet = cat('c2', 'İnternet', parentId: 'r1', sortOrder: 1);
  final faturaSu = cat('c3', 'Su', parentId: 'r1', sortOrder: 2);
  final market = cat('r2', 'Market', sortOrder: 1);
  final marketSu = cat('c4', 'Su', parentId: 'r2', sortOrder: 0);
  final kira = cat('r3', 'Kira', sortOrder: 2);

  final all = [fatura, elektrik, internet, faturaSu, market, marketSu, kira];

  setUpAll(() => getIt.allowReassignment = true);

  // Sahte değil GERÇEK servis: "seçtim, ikinci açılışta şeritte çıktı" zinciri
  // ancak yazma+okumanın ikisi de çalışırsa doğrulanır.
  late RecentCategoriesService recents;

  setUp(() async {
    repository = MockCategoryRepository();
    getIt.registerSingleton<CategoryRepository>(repository);
    when(() => repository.getCategories(any())).thenAnswer((_) async => all);

    SharedPreferences.setMockInitialValues({});
    recents = RecentCategoriesService(await SharedPreferences.getInstance());
    getIt.registerSingleton<RecentCategoriesService>(recents);
  });

  tearDown(() => getIt.reset());

  Widget host(void Function(CategoryEntity?) onPicked, {String? currentId}) =>
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => onPicked(
                await showCategoryPickerSheet(
                  context: context,
                  isExpense: true,
                  currentId: currentId,
                ),
              ),
              child: const Text('Aç'),
            ),
          ),
        ),
      );

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
  }

  group('iki sütun', () {
    // Açılışta sağ sütun SEÇİLİ kategoriyi içeren kökle gelmeli; aksi halde
    // kullanıcı her açılışta nerede olduğunu yeniden bulmak zorunda kalır.
    testWidgets('seçili alt kategorinin kökü açık gelir', (tester) async {
      await tester.pumpWidget(host((_) {}, currentId: 'c4'));
      await open(tester);

      // 'Su' sağ sütunda görünüyor (Market'in altındaki), Elektrik değil.
      expect(find.text('Su'), findsOneWidget);
      expect(find.text('Elektrik'), findsNothing);
    });

    // Sol sütun bir GEZİNME sütunu: dokunmak seçmez. Aynı jestin bazen seçip
    // bazen seçmemesi (çocuksuz kökte doğrudan seçmek gibi) öğrenilebilirliği
    // bozacağı için kural tek: seçim her zaman sağda.
    testWidgets('sol sütuna dokunmak seçmez, sağ sütunu değiştirir',
        (tester) async {
      CategoryEntity? picked;
      var popped = false;
      await tester.pumpWidget(host((c) {
        picked = c;
        popped = true;
      }));
      await open(tester);

      // Açılış: ilk kök (Fatura) sağda.
      expect(find.text('Elektrik'), findsOneWidget);

      await tester.tap(find.text('Market').first);
      await tester.pumpAndSettle();

      expect(popped, isFalse, reason: 'sol sütun sheet\'i kapatmamalı');
      expect(picked, isNull);
      expect(find.text('Elektrik'), findsNothing);
      expect(find.text('Su'), findsOneWidget);
    });

    testWidgets('sağ sütundan alt kategori seçmek onu döner', (tester) async {
      CategoryEntity? picked;
      await tester.pumpWidget(host((c) => picked = c));
      await open(tester);

      await tester.tap(find.text('Elektrik'));
      await tester.pumpAndSettle();

      expect(picked, elektrik);
    });

    // Eski sürümde ana kategoriyi seçmek "Doğrudan «Fatura»" diye ayrı bir
    // italik satırdı. Artık sağ sütunun ilk satırı ana kategorinin KENDİSİ.
    testWidgets('ana kategorinin kendisi sağ sütunun ilk satırından seçilir',
        (tester) async {
      CategoryEntity? picked;
      await tester.pumpWidget(host((c) => picked = c));
      await open(tester);

      expect(find.text('ana kategori'), findsOneWidget);
      // Sol sütunda da 'Fatura' var; sağdaki satır ikincisi.
      await tester.tap(find.text('Fatura').last);
      await tester.pumpAndSettle();

      expect(picked, fatura);
    });

    testWidgets('çocuksuz kök seçilebilir (sağ sütunda tek satır)',
        (tester) async {
      CategoryEntity? picked;
      await tester.pumpWidget(host((c) => picked = c));
      await open(tester);

      await tester.tap(find.text('Kira').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kira').last);
      await tester.pumpAndSettle();

      expect(picked, kira);
    });
  });

  group('arama', () {
    // REGRESYON: filtre ağacında arama vardı, seçicide YOKTU — aynı ağaç iki
    // farklı yetenek konuşuyordu ve 41 satır arama olmadan geziliyordu.
    testWidgets('alt kategori adıyla arayınca düz sonuç verir', (tester) async {
      await tester.pumpWidget(host((_) {}));
      await open(tester);

      await tester.enterText(find.byType(TextField), 'elektrik');
      await tester.pumpAndSettle();

      expect(find.text('Elektrik'), findsOneWidget);
      // İki sütun kalktı: sol sütundaki diğer kökler artık görünmüyor.
      expect(find.text('Market'), findsNothing);
    });

    // Aynı adlı iki alt kategori ("Su") ancak kırıntıyla ayırt edilebilir.
    testWidgets('aynı adlı iki alt kategori ana adıyla ayrışır',
        (tester) async {
      await tester.pumpWidget(host((_) {}));
      await open(tester);

      await tester.enterText(find.byType(TextField), 'su');
      await tester.pumpAndSettle();

      expect(find.text('Su'), findsNWidgets(2));
      expect(find.text('Fatura'), findsOneWidget);
      expect(find.text('Market'), findsOneWidget);
    });

    // `foldTr` olmadan bulunamazdı. (Ölçüldü, Dart 3.12: bozan yön noktasız
    // `I` — 'I'.toLowerCase() 'i' verir, 'ı' değil. 'İ'.toLowerCase() ise düz
    // 'i' üretiyor, birleşen noktalı biçim DEĞİL; bu yorumun eski hali
    // yanlıştı.)
    testWidgets('Türkçe katlama: "internet" → "İnternet"', (tester) async {
      await tester.pumpWidget(host((_) {}));
      await open(tester);

      await tester.enterText(find.byType(TextField), 'internet');
      await tester.pumpAndSettle();

      expect(find.text('İnternet'), findsOneWidget);
    });

    testWidgets('eşleşme yoksa bilgilendirir', (tester) async {
      await tester.pumpWidget(host((_) {}));
      await open(tester);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();

      expect(find.text('Eşleşen kategori yok'), findsOneWidget);
    });

    testWidgets('arama sonucundan seçmek kategoriyi döner', (tester) async {
      CategoryEntity? picked;
      await tester.pumpWidget(host((c) => picked = c));
      await open(tester);

      await tester.enterText(find.byType(TextField), 'elektrik');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elektrik'));
      await tester.pumpAndSettle();

      expect(picked, elektrik);
    });
  });
  group('son kullanılanlar şeridi', () {
    testWidgets('önbellek boşken şerit çıkmaz', (tester) async {
      await tester.pumpWidget(host((_) {}));
      await open(tester);

      expect(find.byType(ActionChip), findsNothing);
    });

    // Zincirin tamamı: seç → önbelleğe yaz → yeniden aç → şeritte gör → çipten
    // seç. Aradaki tek halka koparsa şerit sessizce boş kalır.
    testWidgets('seçilen kategori sonraki açılışta çipte görünür ve seçilir',
        (tester) async {
      CategoryEntity? picked;
      await tester.pumpWidget(host((c) => picked = c));

      await open(tester);
      await tester.tap(find.text('Elektrik'));
      await tester.pumpAndSettle();
      expect(picked, elektrik);

      await open(tester);
      expect(find.byType(ActionChip), findsOneWidget);

      picked = null;
      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();
      expect(picked, elektrik);
    });

    // Silinmiş kategorinin kimliği önbellekte kalır; çözümleme sırasında
    // sessizce düşmeli, yoksa şerit çökerdi ya da hayalet çip gösterirdi.
    testWidgets('silinmiş kategori şeritten sessizce düşer', (tester) async {
      await recents.remember('silinmis-id', true);
      await recents.remember(elektrik.id, true);

      await tester.pumpWidget(host((_) {}));
      await open(tester);

      expect(find.byType(ActionChip), findsOneWidget);
    });

    testWidgets('arama açıkken şerit gizlenir', (tester) async {
      await recents.remember(elektrik.id, true);

      await tester.pumpWidget(host((_) {}));
      await open(tester);
      expect(find.byType(ActionChip), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'su');
      await tester.pumpAndSettle();

      expect(find.byType(ActionChip), findsNothing);
    });
  });
  // Repo'nun tekrar eden tuzağı: dar ekranda taşma. İki sütun önerilirken
  // bilinen risk sol sütunun daralmasıydı — uzun kullanıcı adları orada
  // kırpılabilir. 360×800'de gerçek bir taşma OLMADIĞINI ölçer (taşma
  // debug'da exception atar, `takeException` onu yakalar).
  testWidgets('360dp genişlikte uzun kategori adları taşırmaz', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(() => repository.getCategories(any())).thenAnswer((_) async => [
          cat('r9', 'Sağlık ve Kişisel Bakım Giderleri', sortOrder: 0),
          cat('c9', 'Diş Hekimi ve Ortodonti Kontrolleri',
              parentId: 'r9', sortOrder: 0),
          ...all,
        ]);

    await tester.pumpWidget(host((_) {}));
    await open(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Sağlık ve Kişisel'), findsWidgets);
  });
}
