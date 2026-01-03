import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/repository/receivable_datasource_repository.dart';

class ReceivableRemoteDatasource implements ReceivableDatasourceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'receivables';

  @override
  Future<void> addReceivable(ReceivableModel receivable) async {
    await _firestore
        .collection(_collectionPath)
        .doc(receivable.id)
        .set(_toMap(receivable));
  }

  @override
  Future<void> deleteReceivable(String id) async {
    await _firestore.collection(_collectionPath).doc(id).delete();
  }

  @override
  Future<List<ReceivableModel>> getReceivablesByWalletId(
      String walletId) async {
    final snapshot = await _firestore
        .collection(_collectionPath)
        .where('walletId', isEqualTo: walletId)
        .get();

    return snapshot.docs.map((doc) => _fromMap(doc.data())).toList();
  }

  @override
  Future<void> updateReceivable(ReceivableModel receivable) async {
    await _firestore
        .collection(_collectionPath)
        .doc(receivable.id)
        .update(_toMap(receivable));
  }

  Map<String, dynamic> _toMap(ReceivableModel receivable) {
    return {
      'id': receivable.id,
      'userId': receivable.userId,
      'walletId': receivable.walletId,
      'debtorName': receivable.debtorName,
      'amount': receivable.amount,
      'dueDate': Timestamp.fromDate(receivable.dueDate),
      'isPaid': receivable.isPaid,
      'notes': receivable.notes,
    };
  }

  ReceivableModel _fromMap(Map<String, dynamic> map) {
    return ReceivableModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      walletId: map['walletId'] as String,
      debtorName: map['debtorName'] as String,
      amount: (map['amount'] as num).toDouble(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      isPaid: map['isPaid'] as bool,
      notes: map['notes'] as String?,
    );
  }
}
