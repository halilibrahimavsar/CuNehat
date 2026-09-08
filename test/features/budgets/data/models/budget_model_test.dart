import 'package:cunehat/features/budgets/data/models/budget_model.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetModel', () {
    const testEntity = BudgetEntity(
      categoryId: 'Food',
      limitAmount: 1000.0,
      spentAmount: 0.0, // spentAmount is not saved in local model
    );

    test('fromEntity should return a valid BudgetModel', () {
      final model = BudgetModel.fromEntity(testEntity);

      expect(model.categoryId, testEntity.categoryId);
      expect(model.limitAmount, testEntity.limitAmount);
    });

    test('toEntity should return a valid BudgetEntity', () {
      final model = BudgetModel(
        categoryId: 'Drinks',
        limitAmount: 500.0,
        walletId: 'wallet_123',
      );

      final entity = model.toEntity();

      expect(entity.categoryId, 'Drinks');
      expect(entity.limitAmount, 500.0);
      expect(entity.spentAmount, 0.0); // Default value
    });

    group('JSON gidiş-dönüş (yedek yolu)', () {
      // `fromJson`ın üç alanı da KATI cast; yedek yolunda oldukları hâlde
      // hiç denenmiyorlardı.
      test('toJson → fromJson tüm alanları korur', () {
        final model = BudgetModel(
          categoryId: 'Food',
          limitAmount: 1234.56,
          walletId: 'wallet_123',
        );

        final back = BudgetModel.fromJson(model.toJson());

        expect(back.categoryId, 'Food');
        expect(back.limitAmount, 1234.56);
        expect(back.walletId, 'wallet_123');
      });

      test('spentAmount yedeğe GİRMEZ — anlık hesaplanır', () {
        // Harcanan tutar depoda değil, dönem defterinden türetilir; yedeğe
        // yazmak onu bayat bir sayı olarak geri getirirdi.
        final json = BudgetModel(
          categoryId: 'Food',
          limitAmount: 1000,
          walletId: 'w',
        ).toJson();

        expect(json.containsKey('spentAmount'), isFalse);
        expect(json.keys.toSet(), {'categoryId', 'limitAmount', 'walletId'});
      });

      test('eksik alan sessizce varsayılana düşmez, fırlatır', () {
        final broken = {'categoryId': 'Food', 'walletId': 'w'};
        expect(() => BudgetModel.fromJson(broken), throwsA(anything));
      });
    });

    group('storageKey — bileşik anahtar', () {
      // Bütçeler cüzdan bazlı: anahtar yalnız kategori olsaydı iki cüzdanın
      // aynı kategorideki bütçesi birbirini ezerdi.
      test('walletId::categoryId biçiminde', () {
        final model = BudgetModel(
          categoryId: 'Food',
          limitAmount: 100,
          walletId: 'w1',
        );
        expect(model.storageKey, 'w1::Food');
        expect(BudgetModel.buildStorageKey('w1', 'Food'), model.storageKey);
      });

      test('farklı cüzdanlarda aynı kategori FARKLI anahtar üretir', () {
        expect(BudgetModel.buildStorageKey('w1', 'Food'),
            isNot(BudgetModel.buildStorageKey('w2', 'Food')));
      });
    });
  });
}
