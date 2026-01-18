import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/features/wallet/data/repository/wallet_data_repository.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';

class WalletRemoteDataSource implements WalletDataRepository {
  @override
  Future<String> createWallet(WalletModel wallet) async {
    await FirebaseFirestore.instance
        .collection('wallets')
        .doc(wallet
            .id) // hivedaki create walletta olduğu gibi, yeni id verirsek hangisini sececeğini bilemez
        .set(wallet.toJson());
    return wallet.id!;
  }

  @override
  Future<List<WalletModel>> getWallets(String userId) async {
    final walletsRef = FirebaseFirestore.instance
        .collection('wallets')
        .where('userId', isEqualTo: userId);

    return walletsRef.get().then((snapshot) {
      return snapshot.docs
          .map((doc) => WalletModel.fromJson(
                doc.id,
                doc.data(),
              ))
          .toList();
    });
  }

  @override
  Future<void> updateWallet(WalletModel wallet) async {
    await FirebaseFirestore.instance
        .collection('wallets')
        .doc(wallet.id)
        .update(wallet.toJson());
  }

  @override
  Future<void> deleteWallet(String walletId) async {
    await FirebaseFirestore.instance
        .collection('wallets')
        .doc(walletId)
        .delete();
  }

  @override
  Future<void> setActiveWallet(
      {required String userId, required String newActiveWalletId}) async {
    final walletsRef = FirebaseFirestore.instance.collection('wallets');
    final querySnapshot =
        await walletsRef.where('userId', isEqualTo: userId).get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in querySnapshot.docs) {
      final walletId = doc.id;
      final isActive = walletId == newActiveWalletId;
      batch.update(walletsRef.doc(walletId), {'isActive': isActive});
    }

    await batch.commit();

    // Kullanıcı belgesinde aktif cüzdan ID'sini saklamaya devam edebilirsiniz.
    // final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    // await userRef.update({'activeWalletId': newActiveWalletId});
  }

  @override
  Future<WalletModel?> getActiveWallet(String userId) async {
    final walletsRef = FirebaseFirestore.instance.collection('wallets');
    final querySnapshot =
        await walletsRef.where('userId', isEqualTo: userId).get();
    final activeWallet = querySnapshot.docs.firstWhere(
      (doc) => doc.data()['isActive'] == true,
      orElse: () => querySnapshot.docs.first,
    );
    return WalletModel.fromJson(activeWallet.id, activeWallet.data());
  }

  @override
  Future<void> updateBalance(String userId, double balance) async {
    final activeWallet = await getActiveWallet(userId);
    if (activeWallet != null) {
      final updatedWallet = activeWallet.copyWith(balance: balance);
      await updateWallet(updatedWallet);
    }
  }

  @override
  Future<void> updateDebt(String userId, double debt) async {
    final activeWallet = await getActiveWallet(userId);
    if (activeWallet != null) {
      final updatedWallet = activeWallet.copyWith(debt: debt);
      await updateWallet(updatedWallet);
    }
  }

  @override
  Future<void> updateCredit(String userId, double credit) async {
    final activeWallet = await getActiveWallet(userId);
    if (activeWallet != null) {
      final updatedWallet = activeWallet.copyWith(credit: credit);
      await updateWallet(updatedWallet);
    }
  }

  @override
  Future<void> updateInvestment(String userId, double investment) async {
    final activeWallet = await getActiveWallet(userId);
    if (activeWallet != null) {
      final updatedWallet = activeWallet.copyWith(investment: investment);
      await updateWallet(updatedWallet);
    }
  }
}
