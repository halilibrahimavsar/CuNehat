import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_error_text.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class FakeCategoryEntity extends Fake implements CategoryEntity {}

void main() {
  late MockCategoryRepository repository;

  CategoryEntity cat(
    String id,
    String name, {
    String? parentId,
    bool isExpense = true,
  }) =>
      CategoryEntity(
        id: id,
        name: name,
        iconName: 'category',
        isExpense: isExpense,
        parentId: parentId,
      );

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(FakeCategoryEntity());
  });

  setUp(() {
    repository = MockCategoryRepository();
    getIt.registerSingleton<CategoryRepository>(repository);

    when(() => repository.getCategories(any()))
        .thenAnswer((_) async => <CategoryEntity>[]);
    when(() => repository.getAllCategories())
        .thenAnswer((_) async => <CategoryEntity>[]);
    when(() => repository.updateCategory(any())).thenAnswer((_) async {});
    when(() => repository.addCategory(
              name: any(named: 'name'),
              iconName: any(named: 'iconName'),
              isExpense: any(named: 'isExpense'),
              parentId: any(named: 'parentId'),
            ))
        .thenAnswer((invocation) async =>
            cat('yeni-uuid', invocation.namedArguments[#name] as String));
  });

  tearDown(() => getIt.reset());

  Widget host(Widget child, {Locale locale = const Locale('tr')}) =>
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: locale,
        home: Scaffold(body: child),
      );

  group('yeni kategori', () {
    testWidgets('kimliği repository üretir; çağıran ad göndermekle yetinir',
        (tester) async {
      await tester.pumpWidget(
        host(const CategoryFormSheet(isExpense: true)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Fatura');
      await tester.tap(find.text('Ekle'));
      await tester.pumpAndSettle();

      verify(() => repository.addCategory(
            name: 'Fatura',
            iconName: any(named: 'iconName'),
            isExpense: true,
            parentId: null,
          )).called(1);
    });

    testWidgets('parentId ile açılınca alt kategori olarak kaydeder',
        (tester) async {
      when(() => repository.getCategories(true))
          .thenAnswer((_) async => [cat('f', 'Fatura')]);

      await tester.pumpWidget(
        host(const CategoryFormSheet(isExpense: true, parentId: 'f')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Elektrik');
      await tester.tap(find.text('Ekle'));
      await tester.pumpAndSettle();

      verify(() => repository.addCategory(
            name: 'Elektrik',
            iconName: any(named: 'iconName'),
            isExpense: true,
            parentId: 'f',
          )).called(1);
    });

    testWidgets('üst kategori seçicisinde yalnız ANA kategoriler listelenir',
        (tester) async {
      when(() => repository.getCategories(true)).thenAnswer((_) async => [
            cat('f', 'Fatura'),
            cat('f-e', 'Elektrik', parentId: 'f'),
          ]);

      await tester.pumpWidget(host(const CategoryFormSheet(isExpense: true)));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();

      // Derinlik iki seviyeyle sınırlı: alt kategori üst kategori olamaz.
      expect(find.text('Fatura'), findsWidgets);
      expect(find.text('Elektrik'), findsNothing);
    });

    testWidgets('boş ad reddedilir ve depoya gidilmez', (tester) async {
      await tester.pumpWidget(host(const CategoryFormSheet(isExpense: true)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ekle'));
      await tester.pumpAndSettle();

      expect(find.text('Kategori adı boş olamaz'), findsOneWidget);
      verifyNever(() => repository.addCategory(
            name: any(named: 'name'),
            iconName: any(named: 'iconName'),
            isExpense: any(named: 'isExpense'),
            parentId: any(named: 'parentId'),
          ));
    });

    testWidgets('sistem etiketiyle aynı ad artık serbest', (tester) async {
      // Kimlik UUID olduğundan `tag == 'Transfer'` eşleşmesine giremez;
      // eski rezerve-ad kapısı kaldırıldı.
      await tester.pumpWidget(host(const CategoryFormSheet(isExpense: true)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Transfer');
      await tester.tap(find.text('Ekle'));
      await tester.pumpAndSettle();

      verify(() => repository.addCategory(
            name: 'Transfer',
            iconName: any(named: 'iconName'),
            isExpense: any(named: 'isExpense'),
            parentId: any(named: 'parentId'),
          )).called(1);
    });
  });

  group('düzenleme', () {
    testWidgets('kimlik korunur, yalnız ad değişir', (tester) async {
      final existing = cat('sabit-kimlik', 'Fatura');
      when(() => repository.getCategories(true))
          .thenAnswer((_) async => [existing]);

      await tester.pumpWidget(
        host(CategoryFormSheet(isExpense: true, category: existing)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fatura'), findsWidgets);

      await tester.enterText(find.byType(TextFormField).first, 'Faturalar');
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      final saved = verify(() => repository.updateCategory(captureAny()))
          .captured
          .single as CategoryEntity;
      expect(saved.id, 'sabit-kimlik');
      expect(saved.name, 'Faturalar');
    });

    testWidgets('üst kategori "yok"a çekilince ANA kategoriye yükseltilir',
        (tester) async {
      final child = cat('f-e', 'Elektrik', parentId: 'f');
      when(() => repository.getCategories(true))
          .thenAnswer((_) async => [cat('f', 'Fatura'), child]);

      await tester.pumpWidget(
        host(CategoryFormSheet(isExpense: true, category: child)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ana kategori (üst yok)').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      final saved = verify(() => repository.updateCategory(captureAny()))
          .captured
          .single as CategoryEntity;
      // `parentId: null` geçmek copyWith'te işe yaramaz; clearParent şart.
      expect(saved.parentId, isNull);
    });

    testWidgets('kural ihlali ÇEVRİLMİŞ metne dönüşür', (tester) async {
      // Eskiden ham `Exception('Bu isimde bir kategori zaten var')` metni
      // ekrana basılıyor, İngilizce arayüzde Türkçe görünüyordu. Artık hata
      // tipli; çeviri tek noktada yapılır.
      for (final (locale, expected) in [
        (const Locale('tr'), 'Bu isimde bir kategori zaten var'),
        (const Locale('en'), 'A category with this name already exists'),
      ]) {
        late BuildContext ctx;
        await tester.pumpWidget(host(
          Builder(builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          }),
          locale: locale,
        ));

        expect(
          categoryFailureMessage(
            ctx,
            CategoryException(CategoryValidationError.duplicateSiblingName),
          ),
          expected,
        );
      }
    });

    testWidgets('TÜM kural ihlalleri için çeviri vardır', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(host(
        Builder(builder: (context) {
          ctx = context;
          return const SizedBox.shrink();
        }),
      ));

      for (final error in CategoryValidationError.values) {
        expect(categoryErrorMessage(ctx, error), isNotEmpty,
            reason: '$error için metin yok');
      }
    });
  });
}
