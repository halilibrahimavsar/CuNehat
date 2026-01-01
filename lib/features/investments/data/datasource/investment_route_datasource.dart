import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/data/repository/investment_datasource_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvestmentRouteDatasource implements InvestmentDatasourceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  InvestmentRouteDatasource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  CollectionReference get _investmentsCollection =>
      _firestore.collection('users').doc(_userId).collection('investments');

  @override
  Future<void> addInvestment(InvestmentModel investment) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    // Eğer ID yoksa yeni bir ID oluştur
    final docRef = investment.id != null && investment.id!.isNotEmpty
        ? _investmentsCollection.doc(investment.id)
        : _investmentsCollection.doc();

    final investmentWithId = investment.copyWith(id: docRef.id);
    await docRef.set(investmentWithId.toJson());
  }

  @override
  Future<void> deleteInvestment({required String id}) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');
    await _investmentsCollection.doc(id).delete();
  }

  @override
  Future<List<InvestmentModel>> getInvestments({
    required String userId,
    required String walletId,
  }) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    final snapshot = await _investmentsCollection
        .where('walletId', isEqualTo: walletId)
        .get();
    return snapshot.docs
        .map((doc) => InvestmentModel.fromJson(
            doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateInvestment(InvestmentModel investment) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');
    await _investmentsCollection.doc(investment.id).update(investment.toJson());
  }
}
