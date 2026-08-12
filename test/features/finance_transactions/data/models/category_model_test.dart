import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CategoryModel build({String? parentId}) => CategoryModel(
        id: '018c-uuid',
        name: 'Elektrik',
        iconName: 'lightbulb',
        isExpense: true,
        parentId: parentId,
        sortOrder: 3,
      );

  group('CategoryModel', () {
    test('entity dönüşümü tüm alanları taşır', () {
      final model = build(parentId: 'ana');
      final entity = model.toEntity();

      expect(entity.id, '018c-uuid');
      expect(entity.name, 'Elektrik');
      expect(entity.iconName, 'lightbulb');
      expect(entity.isExpense, isTrue);
      expect(entity.parentId, 'ana');
      expect(entity.sortOrder, 3);

      expect(CategoryModel.fromEntity(entity).toEntity(), entity);
    });

    test('JSON gidiş-dönüşü ana kategoriyi korur', () {
      final model = build();
      final restored = CategoryModel.fromJson(model.toJson());

      expect(restored.toEntity(), model.toEntity());
      expect(restored.parentId, isNull);
    });

    test('JSON gidiş-dönüşü hiyerarşiyi korur', () {
      final model = build(parentId: 'ana');
      expect(CategoryModel.fromJson(model.toJson()).parentId, 'ana');
    });

    test('parentId yedekte açıkça null yazılır', () {
      expect(build().toJson()['parentId'], isNull);
      expect(build().toJson().containsKey('parentId'), isTrue);
    });

    test('fromJson zorunlu alanlarda SIKI davranır', () {
      // Yayın öncesi politika: sürüm-kaynaklı `?? varsayılan` fallback'i yok.
      final json = build().toJson()..remove('name');
      expect(() => CategoryModel.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('eşitlik yalnız kimliğe bakar', () {
      final a = build();
      final b = CategoryModel(
        id: '018c-uuid',
        name: 'Bambaşka',
        iconName: 'category',
        isExpense: false,
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('fromEntity const entity ile çalışır', () {
      const entity = CategoryEntity(
        id: 'x',
        name: 'Market',
        iconName: 'shopping_cart',
        isExpense: true,
      );
      expect(CategoryModel.fromEntity(entity).name, 'Market');
    });
  });
}
