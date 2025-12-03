import 'package:cunehat/features/wallet/data/datasource/wallet_firestore.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_data_service.dart';

class GetStorageMod {
  static WalletDataService dataSource =
      WalletFirestoreDataSource(); // Varsayılan veri kaynağı Firestore

  // Veri kaynağını değiştirmek için statik bir metod.
  static void setDataSource(WalletDataService newDataSource) {
    dataSource = newDataSource;
  }

  static WalletDataService getDataSource() {
    return dataSource;
  }
}
