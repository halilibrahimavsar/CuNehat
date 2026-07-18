import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentModel', () {
    final date = DateTime(2026, 6, 1);
    final entity = Payment(date: date, amount: 100.0, notes: 'Rent');

    test('fromEntity should return valid PaymentModel', () {
      final model = PaymentModel.fromEntity(entity);
      expect(model.date, entity.date);
      expect(model.amount, entity.amount);
      expect(model.notes, entity.notes);
    });

    test('toEntity should return valid Payment', () {
      final model = PaymentModel(date: date, amount: 100.0, notes: 'Rent');
      final entityResult = model.toEntity();
      expect(entityResult.date, model.date);
      expect(entityResult.amount, model.amount);
      expect(entityResult.notes, model.notes);
    });

    test('copyWith returns updated object', () {
      final model = PaymentModel(date: date, amount: 100.0, notes: 'Rent');
      final updated = model.copyWith(amount: 150.0, notes: 'Rent revised');
      expect(updated.amount, 150.0);
      expect(updated.notes, 'Rent revised');
    });

    test('toJson returns correct map', () {
      final model = PaymentModel(date: date, amount: 100.0, notes: 'Rent');
      final json = model.toJson();
      expect(json, {
        'date': date.toIso8601String(),
        'amount': 100.0,
        'notes': 'Rent',
      });
    });

    test('fromJson returns correct object', () {
      final json = {
        'date': date.toIso8601String(),
        'amount': 100.0,
        'notes': 'Rent',
      };
      final model = PaymentModel.fromJson(json);
      expect(model.date, date);
      expect(model.amount, 100.0);
      expect(model.notes, 'Rent');
    });
  });

  group('DebtModel', () {
    final startDate = DateTime(2026, 1, 1);
    final dueDate = DateTime(2026, 12, 1);

    final entity = DebtEntity(
      id: 'debt_1',
      userId: 'user_1',
      walletId: 'wallet_1',
      title: 'Car Loan',
      counterparty: 'Bank A',
      type: DebtType.bankLoan,
      principalAmount: 10000.0,
      interestRate: 12.0,
      termMonths: 12,
      startDate: startDate,
      dueDate: dueDate,
      payments: [Payment(date: startDate, amount: 1000.0, notes: 'First')],
      isPaid: false,
      notes: 'No comments',
      expectedTotalAmount: 11200.0,
    );

    test('fromEntity should return valid DebtModel', () {
      final model = DebtModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.userId, entity.userId);
      expect(model.walletId, entity.walletId);
      expect(model.title, entity.title);
      expect(model.counterparty, entity.counterparty);
      expect(model.type, entity.type);
      expect(model.principalAmount, entity.principalAmount);
      expect(model.interestRate, entity.interestRate);
      expect(model.termMonths, entity.termMonths);
      expect(model.startDate, entity.startDate);
      expect(model.dueDate, entity.dueDate);
      expect(model.payments.length, 1);
      expect(model.payments.first.amount, 1000.0);
      expect(model.isPaid, entity.isPaid);
      expect(model.notes, entity.notes);
      expect(model.expectedTotalAmount, entity.expectedTotalAmount);
    });

    test('toEntity should return valid DebtEntity', () {
      final model = DebtModel(
        id: 'debt_1',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'Car Loan',
        counterparty: 'Bank A',
        type: DebtType.bankLoan,
        principalAmount: 10000.0,
        interestRate: 12.0,
        termMonths: 12,
        startDate: startDate,
        dueDate: dueDate,
        payments: [
          PaymentModel(date: startDate, amount: 1000.0, notes: 'First')
        ],
        isPaid: false,
        notes: 'No comments',
        expectedTotalAmount: 11200.0,
      );

      final entityResult = model.toEntity();
      expect(entityResult.id, model.id);
      expect(entityResult.payments.first.amount, 1000.0);
      expect(entityResult.payments.first is PaymentModel,
          false); // should map to domain Payment
    });

    test('copyWith returns updated object', () {
      final model = DebtModel(
        id: 'debt_1',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'Car Loan',
        counterparty: 'Bank A',
        type: DebtType.bankLoan,
        principalAmount: 10000.0,
        interestRate: 12.0,
        termMonths: 12,
        startDate: startDate,
      );

      final updated = model.copyWith(title: 'Updated Loan', isPaid: true);
      expect(updated.title, 'Updated Loan');
      expect(updated.isPaid, true);
    });

    test('toJson returns correct map', () {
      final model = DebtModel(
        id: 'debt_1',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'Car Loan',
        counterparty: 'Bank A',
        type: DebtType.bankLoan,
        principalAmount: 10000.0,
        interestRate: 12.0,
        termMonths: 12,
        startDate: startDate,
        dueDate: dueDate,
        payments: [
          PaymentModel(date: startDate, amount: 1000.0, notes: 'First')
        ],
        isPaid: false,
        notes: 'No comments',
        expectedTotalAmount: 11200.0,
      );

      final json = model.toJson();
      expect(json['id'], 'debt_1');
      expect(json['userId'], 'user_1');
      expect(json['walletId'], 'wallet_1');
      expect(json['type'], 'bankLoan');
      expect(json['principalAmount'], 10000.0);
      expect(json['payments'].length, 1);
      expect(json['payments'][0]['amount'], 1000.0);
    });

    test('fromJson returns correct object', () {
      final json = {
        'id': 'debt_1',
        'userId': 'user_1',
        'walletId': 'wallet_1',
        'title': 'Car Loan',
        'counterparty': 'Bank A',
        'type': 'bankLoan',
        'principalAmount': 10000.0,
        'interestRate': 12.0,
        'termMonths': 12,
        'startDate': startDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'payments': [
          {
            'date': startDate.toIso8601String(),
            'amount': 1000.0,
            'notes': 'First',
          }
        ],
        'isPaid': false,
        'notes': 'No comments',
        'expectedTotalAmount': 11200.0,
        'overdueInterestRate': 0.0,
        'principalToWallet': true,
      };

      final model = DebtModel.fromJson(json);
      expect(model.id, 'debt_1');
      expect(model.type, DebtType.bankLoan);
      expect(model.payments.length, 1);
      expect(model.payments.first.amount, 1000.0);
      expect(model.payments.first is PaymentModel, true);
    });

    test('fromJson bilinmeyen türde fırlatır (sıkı şema, sessiz düşme yok)',
        () {
      final json = {
        'id': 'debt_1',
        'userId': 'user_1',
        'walletId': 'wallet_1',
        'title': 'Car Loan',
        'counterparty': 'Bank A',
        'type': 'unknown_type_xxx',
        'principalAmount': 10000.0,
        'interestRate': 12.0,
        'termMonths': 12,
        'startDate': startDate.toIso8601String(),
      };

      expect(() => DebtModel.fromJson(json), throwsA(isA<Object>()));
    });
  });
}
