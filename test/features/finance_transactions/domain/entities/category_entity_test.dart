import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CategoryEntity build({
    String id = 'cat-1',
    String name = 'Fatura',
    String iconName = 'receipt_long',
    bool isExpense = true,
    String? parentId,
    int sortOrder = 1,
  }) =>
      CategoryEntity(
        id: id,
        name: name,
        iconName: iconName,
        isExpense: isExpense,
        parentId: parentId,
        sortOrder: sortOrder,
      );

  group('CategoryEntity', () {
    test('parentId null ise ana kategoridir', () {
      expect(build().isRoot, isTrue);
      expect(build(parentId: 'cat-0').isRoot, isFalse);
    });

    test('copyWith kimliği DEĞİŞTİRMEZ', () {
      final original = build(id: 'sabit-kimlik');
      final renamed = original.copyWith(name: 'Yeni Ad');

      expect(renamed.id, 'sabit-kimlik');
      expect(renamed.name, 'Yeni Ad');
    });

    test('copyWith(parentId:) alt kategoriye taşır', () {
      final promoted = build().copyWith(parentId: 'ana');
      expect(promoted.parentId, 'ana');
    });

    test('clearParent alt kategoriyi ana kategoriye YÜKSELTİR', () {
      // `parentId: null` geçmek `?? this.parentId` yüzünden işe yaramaz;
      // yükseltmenin tek yolu bu bayraktır.
      final child = build(parentId: 'ana');

      expect(child.copyWith(parentId: null).parentId, 'ana',
          reason: 'null geçmek sessizce eski değeri korur');
      expect(child.copyWith(clearParent: true).parentId, isNull);
    });

    test('clearParent, parentId ile birlikte verilse de kazanır', () {
      final child = build(parentId: 'ana');
      expect(
        child.copyWith(parentId: 'baska', clearParent: true).parentId,
        isNull,
      );
    });

    test('eşitlik tüm alanları kapsar', () {
      expect(build(), equals(build()));
      expect(build(), isNot(equals(build(name: 'Başka'))));
      expect(build(), isNot(equals(build(parentId: 'ana'))));
      expect(build(), isNot(equals(build(sortOrder: 9))));
    });
  });
}
