import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/repo_services/firestore/firestore_service.dart';
import 'package:cunehat/repository/repo_services/idata_service.dart';
import 'package:cunehat/repository/repo_services/local/local_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GetStorageMod {
  final SharedPreferences _prefs;
  final FirestoreService _firestoreService;
  final LocalDataService _localDataService;

  GetStorageMod({
    required SharedPreferences prefs,
    required FirestoreService firestoreService,
    required LocalDataService localDataService,
  })  : _prefs = prefs,
        _firestoreService = firestoreService,
        _localDataService = localDataService;

  StorageMode getStorageMode() {
    final modeString =
        _prefs.getString(StorageKeys.storageMode) ?? StorageMode.local.name;
    return StorageMode.values.firstWhere((e) => e.name == modeString);
  }

  IDataService get dataService {
    if (getStorageMode() == StorageMode.cloud) {
      return _firestoreService;
    } else {
      return _localDataService;
    }
  }

  Future<void> setStorageMode(StorageMode mode) async {
    print('🔧 [REPO] Setting storage mode: ${mode.name}');
    await _prefs.setString(StorageKeys.storageMode, mode.name);
  }

  bool get isCloudMode => getStorageMode() == StorageMode.cloud;
}
