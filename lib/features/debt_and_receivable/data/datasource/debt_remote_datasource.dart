import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/repository/debt_datasource_repository.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';

class DebtRemoteDatasource implements DebtDatasourceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'debts';

  @override
  Future<void> addDebt(DebtModel debt) async {
    await _firestore.collection(_collectionPath).doc(debt.id).set(_toMap(debt));
  }

  @override
  Future<void> deleteDebt(String id) async {
    await _firestore.collection(_collectionPath).doc(id).delete();
  }

  @override
  Future<List<DebtModel>> getDebtsByWalletId(String walletId) async {
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('walletId', isEqualTo: walletId)
        .get();

    return snapshot.docs.map((doc) => _fromMap(doc.data())).toList();
  }

  @override
  Future<void> updateDebt(DebtModel debt) async {
    await _firestore
        .collection(_collectionPath)
        .doc(debt.id)
        .update(_toMap(debt));
  }

  // Helper: Model -> Map (Firestore Yazma)
  Map<String, dynamic> _toMap(DebtModel debt) {
    return {
      'id': debt.id,
      'userId': debt.userId,
      'walletId': debt.walletId,
      'title': debt.title,
      'counterparty': debt.counterparty,
      'type': debt.type.name, // Enum -> String
      'principalAmount': debt.principalAmount,
      'interestRate': debt.interestRate,
      'termMonths': debt.termMonths,
      'overdueInterestRate': debt.overdueInterestRate,
      'startDate': Timestamp.fromDate(debt.startDate),
      'dueDate':
          debt.dueDate != null ? Timestamp.fromDate(debt.dueDate!) : null,
      'payments': debt.payments
          .map((p) => {
                'date': Timestamp.fromDate(p.date),
                'amount': p.amount,
                'notes': p.notes,
              })
          .toList(),
      'isPaid': debt.isPaid,
      'notes': debt.notes,
    };
  }

  // Helper: Map -> Model (Firestore Okuma)
  DebtModel _fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      walletId: map['walletId'] as String,
      title: map['title'] as String,
      counterparty: map['counterparty'] as String,
      type: DebtType.values.firstWhere((e) => e.name == map['type']),
      principalAmount: (map['principalAmount'] as num).toDouble(),
      interestRate: (map['interestRate'] as num).toDouble(),
      termMonths: map['termMonths'] as int,
      overdueInterestRate: (map['overdueInterestRate'] as num).toDouble(),
      startDate: (map['startDate'] as Timestamp).toDate(),
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
      payments: (map['payments'] as List<dynamic>).map((p) {
        final pMap = p as Map<String, dynamic>;
        return PaymentModel(
          date: (pMap['date'] as Timestamp).toDate(),
          amount: (pMap['amount'] as num).toDouble(),
          notes: pMap['notes'] as String?,
        );
      }).toList(),
      isPaid: map['isPaid'] as bool,
      notes: map['notes'] as String?,
    );
  }
}
