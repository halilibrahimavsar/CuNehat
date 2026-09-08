import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/recurring_transactions/data/models/recurring_transaction_model.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecurringTransactionModel', () {
    final nextDate = DateTime(2026, 6, 15);
    final entity = RecurringTransactionEntity(
      id: 'rec_1',
      userId: 'user_1',
      walletId: 'wallet_1',
      title: 'Rent',
      tag: 'housing',
      amount: 1500.0,
      type: TransactionTypeModel.expense,
      frequency: RecurringFrequency.monthly,
      nextExecutionDate: nextDate,
      anchorDay: nextDate.day,
      isActive: true,
    );

    test('is a subclass of RecurringTransactionEntity', () {
      final model = RecurringTransactionModel.fromEntity(entity);
      expect(model, isA<RecurringTransactionEntity>());
    });

    test('fromEntity should return a valid model matching the entity', () {
      final model = RecurringTransactionModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.userId, entity.userId);
      expect(model.walletId, entity.walletId);
      expect(model.title, entity.title);
      expect(model.tag, entity.tag);
      expect(model.amount, entity.amount);
      expect(model.type, entity.type);
      expect(model.frequency, entity.frequency);
      expect(model.nextExecutionDate, entity.nextExecutionDate);
      expect(model.isActive, entity.isActive);
    });

    test('toEntity should return a valid entity matching the model', () {
      final model = RecurringTransactionModel(
        id: 'rec_1',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'Rent',
        tag: 'housing',
        amount: 1500.0,
        type: TransactionTypeModel.expense,
        frequency: RecurringFrequency.monthly,
        nextExecutionDate: nextDate,
        anchorDay: nextDate.day,
        isActive: true,
      );

      final mappedEntity = model.toEntity();
      expect(mappedEntity, entity);
    });

    group('JSON gidiş-dönüş (yedek yolu)', () {
      // `fromJson`ın ON BİR alanı da KATI cast — `anchorDay` (v3) ve
      // `isActive` dahil — ve yedek yolunda oldukları hâlde hiç denenmiyordu.
      test('toJson → fromJson tüm alanları korur', () {
        final model = RecurringTransactionModel.fromEntity(entity);

        final back = RecurringTransactionModel.fromJson(model.toJson());

        expect(back.id, model.id);
        expect(back.userId, model.userId);
        expect(back.walletId, model.walletId);
        expect(back.title, model.title);
        expect(back.tag, model.tag);
        expect(back.amount, model.amount);
        expect(back.type, model.type);
        expect(back.frequency, model.frequency);
        expect(back.nextExecutionDate, model.nextExecutionDate);
        expect(back.anchorDay, model.anchorDay);
        expect(back.isActive, model.isActive);
      });

      test('ÇAPA ayrı taşınır — vadenin gününden türetilemez', () {
        // 31 Oca çapası kısa ayda 28'e kenetlenir; vade tarihinden geri
        // türetmek çapayı kalıcı olarak aşağı çeker (maaş/kira şablonları
        // ilk Şubat'tan sonra sonsuza dek 28'e kayardı).
        final clamped = RecurringTransactionModel(
          id: 'r1',
          userId: 'u',
          walletId: 'w',
          title: 'Kira',
          tag: 'Fatura',
          amount: 7500,
          type: TransactionTypeModel.expense,
          frequency: RecurringFrequency.monthly,
          nextExecutionDate: DateTime(2026, 2, 28),
          anchorDay: 31,
          isActive: true,
        );

        final back = RecurringTransactionModel.fromJson(clamped.toJson());

        expect(back.anchorDay, 31);
        expect(back.nextExecutionDate.day, 28);
      });

      test('enum ADIYLA taşınır (index ile değil)', () {
        // Yedekte index taşımak, enum sırası değişince tüm şablonların
        // türünü/frekansını sessizce kaydırırdı.
        final json = RecurringTransactionModel.fromEntity(entity).toJson();
        expect(json['type'], 'expense');
        expect(json['frequency'], 'monthly');
      });

      test('eksik alan sessizce varsayılana düşmez, fırlatır', () {
        final broken = RecurringTransactionModel.fromEntity(entity).toJson()
          ..remove('anchorDay');
        expect(() => RecurringTransactionModel.fromJson(broken),
            throwsA(anything));
      });
    });
  });
}
