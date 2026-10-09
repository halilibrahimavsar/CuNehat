import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionModel', () {
    final date = DateTime(2026, 6, 1);
    final entity = TransactionEntity(
      id: 'tx_1',
      userId: 'user_1',
      walletId: 'wallet_1',
      title: 'Lunch',
      tag: 'Food',
      amount: 250.0,
      date: date,
      type: TransactionTypeModel.expense,
      isSystem: false,
    );

    test('toEntity should return a valid TransactionEntity', () {
      final model = TransactionModel(
        id: 'tx_1',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'Lunch',
        tag: 'Food',
        amount: 250.0,
        date: date,
        type: TransactionTypeModel.expense,
        isSystem: false,
      );
      final resultEntity = model.toEntity();
      expect(resultEntity, entity);
    });

    test('fromEntity should return a valid TransactionModel', () {
      final model = TransactionModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.userId, entity.userId);
      expect(model.walletId, entity.walletId);
      expect(model.title, entity.title);
      expect(model.tag, entity.tag);
      expect(model.amount, entity.amount);
      expect(model.date, entity.date);
      expect(model.type, entity.type);
      expect(model.isSystem, entity.isSystem);
    });

    test('toJson returns correct map', () {
      final model = TransactionModel(
        id: 'tx_1',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'Lunch',
        tag: 'Food',
        amount: 250.0,
        date: date,
        type: TransactionTypeModel.expense,
        isSystem: false,
      );
      final json = model.toJson();
      expect(json, {
        'id': 'tx_1',
        'userId': 'user_1',
        'walletId': 'wallet_1',
        'title': 'Lunch',
        'tag': 'Food',
        'amount': 250.0,
        'date': date.toIso8601String(),
        'type': 'expense',
        'isSystem': false,
        'receiptFileName': null,
        'reference': null,
        // v11
        'linkedRecordId': null,
        'adoptedFromTag': null,
        'origin': null,
        // v13
        'importBatchId': null,
        // v15
        'installmentGroupId': null,
        'installmentNo': null,
        'installmentCount': null,
      });
    });

    test('fromJson returns correct object', () {
      final json = {
        'userId': 'user_1',
        'walletId': 'wallet_1',
        'title': 'Lunch',
        'tag': 'Food',
        'amount': 250.0,
        'date': date.toIso8601String(),
        'type': 'expense',
        'isSystem': false,
      };
      final model = TransactionModel.fromJson('tx_1', json);
      expect(model.id, 'tx_1');
      expect(model.userId, 'user_1');
      expect(model.walletId, 'wallet_1');
      expect(model.title, 'Lunch');
      expect(model.tag, 'Food');
      expect(model.amount, 250.0);
      expect(model.date, date);
      expect(model.type, TransactionTypeModel.expense);
      expect(model.isSystem, false);
    });

    test('v11 alanları JSON gidiş-dönüşünde korunur', () {
      final model = TransactionModel(
        id: 'tx_9',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'MIDAS MENKUL DEGERLER',
        tag: 'Yatırım Alımı',
        amount: 5000,
        date: date,
        type: TransactionTypeModel.expense,
        isSystem: true,
        reference: 'DK-1',
        linkedRecordId: 'inv-1',
        adoptedFromTag: 'cat-yatirim',
        origin: 'import',
      );
      final back = TransactionModel.fromJson('tx_9', model.toJson());
      expect(back, model);
      expect(TransactionModel.fromEntity(model.toEntity()), model);
    });

    test('v13 içe aktarım partisi JSON ve varlık gidiş-dönüşünde korunur', () {
      final model = TransactionModel(
        id: 'tx_10',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'MIGROS',
        tag: 'cat-market',
        amount: 91.5,
        date: date,
        type: TransactionTypeModel.expense,
        origin: 'import',
        importBatchId: '01922b7e-3f00-7abc-8def-0123456789ab',
      );
      final back = TransactionModel.fromJson('tx_10', model.toJson());
      expect(back.importBatchId, '01922b7e-3f00-7abc-8def-0123456789ab');
      expect(back, model);
      expect(TransactionModel.fromEntity(model.toEntity()), model);
      // Düzenleme formu ve benimsemeden dönüş partiyi DÜŞÜRMEZ: aksi hâlde
      // kategorisi düzeltilen satır "Son içe aktarımlar"dan kopardı.
      expect(
          model
              .edited(
                title: 'MIGROS',
                tag: 'cat-other',
                amount: 91.5,
                date: date,
                type: TransactionTypeModel.expense,
                receiptFileName: null,
              )
              .importBatchId,
          model.importBatchId);
      expect(model.released().importBatchId, model.importBatchId);
    });

    test('v15 taksit grubu JSON/varlık gidiş-dönüşünde ve düzenlemede korunur',
        () {
      final model = TransactionModel(
        id: 'tx_11',
        userId: 'user_1',
        walletId: 'card',
        title: 'Laptop (2/6)',
        tag: 'cat-tech',
        amount: 5000,
        date: date,
        type: TransactionTypeModel.expense,
        installmentGroupId: 'g-1',
        installmentNo: 2,
        installmentCount: 6,
      );
      final back = TransactionModel.fromJson('tx_11', model.toJson());
      expect(back, model);
      expect(TransactionModel.fromEntity(model.toEntity()), model);
      // Düzenleme formu grubu DÜŞÜRMEZ (yalnız bu taksitin tutarı değişse
      // de satır gruptan kopmamalı).
      final edited = model.edited(
        title: 'Laptop (2/6)',
        tag: 'cat-tech',
        amount: 4999,
        date: date,
        type: TransactionTypeModel.expense,
        receiptFileName: null,
      );
      expect(edited.installmentGroupId, 'g-1');
      expect(edited.installmentNo, 2);
      expect(edited.installmentCount, 6);
    });

    test('v12 JSON\'u (anahtar yok) partisiz okunur', () {
      final model = TransactionModel.fromJson('tx_1', {
        'userId': 'user_1',
        'walletId': 'wallet_1',
        'title': 'Lunch',
        'tag': 'Food',
        'amount': 250.0,
        'date': date.toIso8601String(),
        'type': 'expense',
        'isSystem': false,
      });
      expect(model.importBatchId, isNull);
    });

    test('fromJson throws Exception for invalid date format', () {
      final json = {
        'userId': 'user_1',
        'walletId': 'wallet_1',
        'title': 'Lunch',
        'tag': 'Food',
        'amount': 250.0,
        'date': 12345678, // invalid date type
        'type': 'expense',
        'isSystem': false,
      };
      expect(() => TransactionModel.fromJson('tx_1', json), throwsException);
    });

    test('copyWith returns updated object', () {
      final model = TransactionModel(
        id: 'tx_1',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'Lunch',
        tag: 'Food',
        amount: 250.0,
        date: date,
        type: TransactionTypeModel.expense,
      );

      final updated = model.copyWith(title: 'Dinner', amount: 300.0);
      expect(updated.title, 'Dinner');
      expect(updated.amount, 300.0);
      expect(updated.id, 'tx_1');
    });

    group('receiptFileName (fiş eki)', () {
      test('defaults to null when not provided', () {
        final model = TransactionModel.fromEntity(entity);
        expect(model.receiptFileName, isNull);
      });

      test('survives toJson/fromJson round-trip (yedek uyumu)', () {
        final model = TransactionModel(
          id: 'tx_9',
          userId: 'user_1',
          walletId: 'wallet_1',
          title: 'Market',
          tag: 'Food',
          amount: 99.9,
          date: date,
          type: TransactionTypeModel.expense,
          receiptFileName: 'abc-123.jpg',
        );
        final restored = TransactionModel.fromJson('tx_9', model.toJson());
        expect(restored.receiptFileName, 'abc-123.jpg');
      });

      test('fromJson reads null receiptFileName when key absent', () {
        final json = {
          'userId': 'user_1',
          'walletId': 'wallet_1',
          'title': 'Lunch',
          'tag': 'Food',
          'amount': 250.0,
          'date': date.toIso8601String(),
          'type': 'expense',
          'isSystem': false,
        };
        final model = TransactionModel.fromJson('tx_1', json);
        expect(model.receiptFileName, isNull);
      });

      test('entity <-> model preserves receiptFileName', () {
        final withReceipt = entity.copyWith(receiptFileName: 'r.jpg');
        final model = TransactionModel.fromEntity(withReceipt);
        expect(model.receiptFileName, 'r.jpg');
        expect(model.toEntity().receiptFileName, 'r.jpg');
      });
    });

    group('reference (banka hareket no — şema v5)', () {
      /// Yedek gidiş-dönüşü bu alanı taşımazsa, geri yüklenen defterde
      /// içe aktarımlar arası tekrar tespiti sessizce zayıf anahtara düşer.
      test('toJson/fromJson referansı korur', () {
        final model = TransactionModel(
          id: 'tx_9',
          userId: 'user_1',
          walletId: 'wallet_1',
          title: 'SATIŞ-KARACA OTOMAT',
          tag: 'Market',
          amount: 40,
          date: date,
          type: TransactionTypeModel.expense,
          reference: '2025-07-07-16.45.14.329462',
        );
        final restored = TransactionModel.fromJson('tx_9', model.toJson());
        expect(restored.reference, '2025-07-07-16.45.14.329462');
      });

      test('elle girilen işlemde referans null kalır', () {
        expect(TransactionModel.fromEntity(entity).reference, isNull);
        expect(TransactionModel.fromJson('tx_1', entity.toJson()).reference,
            isNull);
      });

      test('entity <-> model referansı korur', () {
        final withRef = entity.copyWith(reference: 'DEKONT-7');
        final model = TransactionModel.fromEntity(withRef);
        expect(model.reference, 'DEKONT-7');
        expect(model.toEntity().reference, 'DEKONT-7');
      });
    });
  });
}
