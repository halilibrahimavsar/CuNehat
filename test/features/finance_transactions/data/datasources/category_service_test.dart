import 'dart:convert';

import 'package:cunehat/features/finance_transactions/data/datasources/category_service.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late CategoryService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = CategoryService();
  });

  group('CategoryService', () {
    const customExpense = CategoryModel(
      id: 'Custom Food',
      iconName: 'restaurant',
      isExpense: true,
      isDefault: false,
      sortOrder: 10,
    );

    test(
        'should return default categories when no custom categories are stored',
        () async {
      final expenses = await service.getExpenseCategories();
      final incomes = await service.getIncomeCategories();

      expect(
          expenses.length, CategoryModel.getDefaultExpenseCategories().length);
      expect(incomes.length, CategoryModel.getDefaultIncomeCategories().length);
      expect(expenses.first.isDefault, true);
    });

    test('should add custom category successfully', () async {
      await service.addCategory(customExpense);

      final expenses = await service.getExpenseCategories();

      expect(expenses.length,
          CategoryModel.getDefaultExpenseCategories().length + 1);
      expect(expenses.any((c) => c.id == 'Custom Food'), true);
    });

    test('should throw error when adding default category', () async {
      const defaultCat = CategoryModel(
        id: 'Yemek',
        iconName: 'restaurant',
        isExpense: true,
        isDefault: true,
      );

      expect(() => service.addCategory(defaultCat), throwsException);
    });

    test('should throw error when category name already exists', () async {
      await service.addCategory(customExpense);
      expect(() => service.addCategory(customExpense), throwsException);
    });

    test('sistem etiketiyle aynı adlı kategori reddedilir', () async {
      // Bütçe/rapor `tag == categoryId` ile eşleşir; "Borç Ödemesi" adlı
      // kategori sistem hareketlerini kendine sayardı.
      const reserved = CategoryModel(
        id: 'Borç Ödemesi',
        iconName: 'payment',
        isExpense: true,
        isDefault: false,
      );
      expect(() => service.addCategory(reserved), throwsException);

      // Büyük/küçük harf farkı da korumayı aşamaz.
      const reservedLower = CategoryModel(
        id: 'transfer',
        iconName: 'swap',
        isExpense: true,
        isDefault: false,
      );
      expect(() => service.addCategory(reservedLower), throwsException);
    });

    test('should update custom category successfully', () async {
      await service.addCategory(customExpense);

      final updated = customExpense.copyWith(iconName: 'updated_icon');
      await service.updateCategory(updated);

      final expenses = await service.getExpenseCategories();
      final category = expenses.firstWhere((c) => c.id == 'Custom Food');
      expect(category.iconName, 'updated_icon');
    });

    test('should update default category in updated defaults', () async {
      final defaultExpense = CategoryModel.getDefaultExpenseCategories().first;
      final updatedDefault = defaultExpense.copyWith(sortOrder: 100);

      await service.updateCategory(updatedDefault);

      final expenses = await service.getExpenseCategories();
      final category = expenses.firstWhere((c) => c.id == defaultExpense.id);
      expect(category.sortOrder, 100);
    });

    test('should delete custom category successfully', () async {
      await service.addCategory(customExpense);
      await service.deleteCategory('Custom Food', true);

      final expenses = await service.getExpenseCategories();
      expect(expenses.any((c) => c.id == 'Custom Food'), false);
    });

    test(
        'should throw error when updating default category that does not exist in defaults',
        () async {
      const nonExistentDefault = CategoryModel(
        id: 'NonExistentDefault',
        iconName: 'help',
        isExpense: true,
        isDefault: true,
      );
      expect(() => service.updateCategory(nonExistentDefault), throwsException);
    });

    test('should throw error when updating custom category that does not exist',
        () async {
      const nonExistentCustom = CategoryModel(
        id: 'NonExistentCustom',
        iconName: 'help',
        isExpense: true,
        isDefault: false,
      );
      expect(() => service.updateCategory(nonExistentCustom), throwsException);
    });

    test('should load existing updated defaults when updating again', () async {
      final defaultExpense = CategoryModel.getDefaultExpenseCategories().first;
      final updatedDefault1 = defaultExpense.copyWith(sortOrder: 100);
      await service.updateCategory(updatedDefault1);

      final updatedDefault2 = defaultExpense.copyWith(sortOrder: 200);
      await service.updateCategory(updatedDefault2);

      final expenses = await service.getExpenseCategories();
      final category = expenses.firstWhere((c) => c.id == defaultExpense.id);
      expect(category.sortOrder, 200);
    });

    test(
        'should update default income category successfully and hit default income fallback path',
        () async {
      final defaultIncome = CategoryModel.getDefaultIncomeCategories().first;
      final updatedIncome = defaultIncome.copyWith(sortOrder: 150);

      await service.updateCategory(updatedIncome);

      final incomes = await service.getIncomeCategories();
      final category = incomes.firstWhere((c) => c.id == defaultIncome.id);
      expect(category.sortOrder, 150);
    });
    // ---------------------------------------------------------- Yeniden adlandırma
    //
    // REGRESYON: form eskiden `copyWith(id: yeniAd)` gönderiyordu; updateCategory
    // kaydı id ile aradığından HİÇBİR yeniden adlandırma kaydedilemiyordu
    // (özelde "Özel kategori bulunamadı", varsayılanda "Varsayılan kategori
    // bulunamadı"). Yalnız ikon değişikliği çalışıyordu. Artık ad `displayName`
    // üzerinden değişir, `id` sabit kalır.

    test('özel kategori yeniden adlandırılır, id DEĞİŞMEZ', () async {
      const custom = CategoryModel(
        id: 'Kahve',
        displayName: 'Kahve',
        iconName: 'restaurant',
        isExpense: true,
        sortOrder: 10,
      );
      await service.addCategory(custom);

      await service
          .updateCategory(custom.copyWith(displayName: 'Kahve Dükkanı'));

      final c = (await service.getExpenseCategories())
          .firstWhere((x) => x.id == 'Kahve');
      // id sabit: bu kategoriye yazılmış işlemlerin `tag`'i ve bütçe anahtarı
      // (walletId::categoryId) yetim kalmasın.
      expect(c.id, 'Kahve');
      expect(c.displayName, 'Kahve Dükkanı');
    });

    test('varsayılan kategori yeniden adlandırılır, id DEĞİŞMEZ', () async {
      final def = CategoryModel.getDefaultExpenseCategories()
          .firstWhere((c) => c.id == 'Yemek');

      await service.updateCategory(def.copyWith(displayName: 'Dışarıda Yemek'));

      final c = (await service.getExpenseCategories())
          .firstWhere((x) => x.id == 'Yemek');
      expect(c.id, 'Yemek');
      expect(c.displayName, 'Dışarıda Yemek');
      expect(c.isDefault, isTrue);
    });

    test('aynı görünen ada sahip ikinci kategori reddedilir', () async {
      const custom = CategoryModel(
        id: 'Kahve',
        displayName: 'Kahve',
        iconName: 'restaurant',
        isExpense: true,
      );
      await service.addCategory(custom);

      // Var olan bir varsayılanın ham etiketiyle çakışma
      expect(
        () => service.updateCategory(custom.copyWith(displayName: 'Market')),
        throwsException,
      );
    });

    test('kategori kendi adına yeniden adlandırılabilir (no-op)', () async {
      const custom = CategoryModel(
        id: 'Kahve',
        displayName: 'Kahve',
        iconName: 'restaurant',
        isExpense: true,
      );
      await service.addCategory(custom);

      // Yalnız ikon değişiyor: kendi etiketi çakışma sayılmamalı.
      await service.updateCategory(custom.copyWith(iconName: 'movie'));

      final c = (await service.getExpenseCategories())
          .firstWhere((x) => x.id == 'Kahve');
      expect(c.iconName, 'movie');
    });

    test(
        'koda sonradan eklenen varsayılanlar, bir varsayılan düzenlenmiş olsa '
        'bile görünür', () async {
      // REGRESYON: kayıtlı "güncellenmiş varsayılanlar" listesi eskiden
      // koddaki listenin YERİNE geçiyordu; bir varsayılana bir kez
      // dokunulduktan sonra yeni varsayılanlar hiç ortaya çıkmıyordu.
      final def = CategoryModel.getDefaultExpenseCategories().first;
      await service.updateCategory(def.copyWith(iconName: 'movie'));

      final ids = (await service.getExpenseCategories()).map((c) => c.id);
      final expected =
          CategoryModel.getDefaultExpenseCategories().map((c) => c.id);
      expect(ids, containsAll(expected));
    });

    test('yerelleşmiş adla çakışan özel kategori reddedilir', () async {
      // REGRESYON: koruma ham etikete (`displayName ?? id`) bakıyordu.
      // İngilizce'de 'Yemek' varsayılanı 'Food' görünürken kullanıcı 'Food'
      // adlı özel kategori ekleyebiliyordu: id çakışması yok ('Food' ≠
      // 'Yemek'), ham etiket çakışması da yok — ama listede iki tane 'Food'
      // satırı beliriyor, ikisi de bütçelenebilir ve seçilebiliyordu.
      const custom = CategoryModel(
        id: 'Food',
        displayName: 'Food',
        iconName: 'restaurant',
        isExpense: true,
      );

      // Sunum katmanının gördüğü adlar (İngilizce yerel).
      const englishLabels = {'Yemek': 'Food', 'Market': 'Groceries'};

      expect(
        () => service.addCategory(custom, displayLabels: englishLabels),
        throwsException,
      );

      // Harita verilmezse eski (kör) davranış: veri katmanı ham etikete düşer.
      await service.addCategory(custom);
      expect((await service.getExpenseCategories()).any((c) => c.id == 'Food'),
          isTrue);
    });

    test('yeniden adlandırma yerelleşmiş bir adla çakışamaz', () async {
      const custom = CategoryModel(
        id: 'Kahve',
        displayName: 'Kahve',
        iconName: 'local_cafe',
        isExpense: true,
      );
      await service.addCategory(custom);

      const englishLabels = {'Yemek': 'Food', 'Kahve': 'Kahve'};

      expect(
        () => service.updateCategory(
          custom.copyWith(displayName: 'Food'),
          // Hedef ad kendi id'si altında taşınır.
          displayLabels: {...englishLabels, 'Kahve': 'Food'},
        ),
        throwsException,
      );
    });

    test('kategori kendi yerelleşmiş adıyla çakışmış sayılmaz', () async {
      // Yalnız ikon değişirken hedef ad kategorinin KENDİ görünen adıdır;
      // `exceptId` bunu dışarıda bırakmazsa hiçbir düzenleme kaydedilemezdi.
      final def = CategoryModel.getDefaultExpenseCategories()
          .firstWhere((c) => c.id == 'Yemek');

      await service.updateCategory(
        def.copyWith(iconName: 'movie'),
        displayLabels: const {'Yemek': 'Food', 'Market': 'Groceries'},
      );

      final c = (await service.getExpenseCategories())
          .firstWhere((x) => x.id == 'Yemek');
      expect(c.iconName, 'movie');
    });

    test(
        'kayıtlı düzenlemeler bayatsa, koda sonradan eklenen varsayılanın '
        'düzenlemesi yine de kaydedilir', () async {
      // REGRESYON: kayıtlı liste, o sürümde henüz var olmayan varsayılanları
      // içermez. _getUpdatedDefaults yalnız ZATEN VAR OLAN id'yi güncelliyor,
      // yoksa eklemiyordu → yeni varsayılana yapılan düzenleme sessizce
      // düşüyor, updateCategory yine de başarıyla dönüyordu ("Kategori Düzenle
      // çalışmıyor" şikayetinin bu diff'ten sonra hayatta kalan kolu).
      SharedPreferences.setMockInitialValues({
        'updated_expense_defaults': json.encode([
          {
            'id': 'Yemek',
            'displayName': null,
            'iconName': 'movie',
            'isExpense': true,
            'isDefault': true,
            'sortOrder': 2,
          },
        ]),
      });
      service = CategoryService();

      final market = CategoryModel.getDefaultExpenseCategories()
          .firstWhere((c) => c.id == 'Market');
      await service.updateCategory(market.copyWith(displayName: 'Bakkal'));

      final all = await service.getExpenseCategories();
      expect(all.firstWhere((c) => c.id == 'Market').displayName, 'Bakkal');
      // Önceki düzenleme kaybolmaz.
      expect(all.firstWhere((c) => c.id == 'Yemek').iconName, 'movie');
    });

    test('dokunulmamış varsayılanlar override olarak yazılmaz', () async {
      // Hepsi tohumlanırsa koddaki sonraki bir ikon/ad değişikliğini bayat
      // override kalıcı olarak maskeler.
      final def = CategoryModel.getDefaultExpenseCategories().first;
      await service.updateCategory(def.copyWith(iconName: 'movie'));

      final prefs = await SharedPreferences.getInstance();
      final stored = json.decode(prefs.getString('updated_expense_defaults')!)
          as List<dynamic>;
      expect(stored, hasLength(1));
      expect((stored.single as Map<String, dynamic>)['id'], def.id);
    });
  });
}
