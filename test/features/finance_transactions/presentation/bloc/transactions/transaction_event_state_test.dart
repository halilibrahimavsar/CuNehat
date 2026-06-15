import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:flutter_test/flutter_test.dart';

class MockTransactionEvent extends TransactionEvent {
  const MockTransactionEvent();
}

class MockTransactionState extends TransactionState {
  const MockTransactionState();
}

void main() {
  final testTransaction = TransactionEntity(
    id: 'tx_123',
    userId: 'user_123',
    walletId: 'wallet_123',
    title: 'Grocery',
    tag: 'Food',
    amount: 150.0,
    date: DateTime(2026, 6, 13),
    type: TransactionTypeModel.expense,
  );

  group('TransactionEvent Equatable', () {
    test('GetTransactionsEvent props', () {
      final date = DateTime(2026, 6, 13);
      final event = GetTransactionsEvent(
        userId: 'user_123',
        walletId: 'wallet_123',
        startDate: date,
        endDate: date,
        type: TransactionTypeModel.expense,
      );
      expect(event.props,
          ['user_123', 'wallet_123', date, date, TransactionTypeModel.expense]);
    });

    test('AddTransactionEvent props', () {
      final event = AddTransactionEvent(testTransaction);
      expect(event.props, [testTransaction]);
    });

    test('UpdateTransactionEvent props', () {
      final event = UpdateTransactionEvent(
        previousTransaction: testTransaction,
        newTransaction: testTransaction,
      );
      expect(event.props, [testTransaction, testTransaction]);
    });

    test('DeleteTransactionEvent props', () {
      final event = const DeleteTransactionEvent('tx_123');
      expect(event.props, ['tx_123']);
    });

    test('MockTransactionEvent props', () {
      expect(const MockTransactionEvent().props, isEmpty);
    });
  });

  group('TransactionState Equatable and Helpers', () {
    test('MockTransactionState props and currentTransactions', () {
      const state = MockTransactionState();
      expect(state.props, isEmpty);
      expect(state.currentTransactions, isEmpty);
    });

    test('TransactionLoading defaults and props', () {
      const state = TransactionLoading();
      expect(state.currentTransactions, isEmpty);
      expect(state.props, [const <TransactionEntity>[]]);

      final stateWithPrev =
          TransactionLoading(previousTransactions: [testTransaction]);
      expect(stateWithPrev.currentTransactions, [testTransaction]);
      expect(stateWithPrev.props, [
        [testTransaction]
      ]);
    });

    test('TransactionLoaded props and currentTransactions', () {
      final grouped = {
        DateTime(2026, 6, 13): [testTransaction]
      };
      final state = TransactionLoaded(
        groupedTransactions: grouped,
        allTransactions: [testTransaction],
      );
      expect(state.currentTransactions, [testTransaction]);
      expect(state.props, [
        grouped,
        [testTransaction]
      ]);
    });

    test('TransactionError defaults and props', () {
      const state = TransactionError('error');
      expect(state.currentTransactions, isEmpty);
      expect(state.props, ['error', const <TransactionEntity>[]]);

      final stateWithData =
          TransactionError('error', transactions: [testTransaction]);
      expect(stateWithData.currentTransactions, [testTransaction]);
      expect(stateWithData.props, [
        'error',
        [testTransaction]
      ]);
    });

    test('TransactionActionSuccess defaults and props', () {
      const state = TransactionActionSuccess('success');
      expect(state.currentTransactions, isEmpty);
      expect(state.props, ['success', const <TransactionEntity>[], null]);

      final stateWithData = TransactionActionSuccess(
        'success',
        transactions: [testTransaction],
        warning: 'warning',
      );
      expect(stateWithData.currentTransactions, [testTransaction]);
      expect(stateWithData.props, [
        'success',
        [testTransaction],
        'warning'
      ]);
    });
  });
}
