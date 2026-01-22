import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

// TODO : move this file to where the implementation files stores
/// Network information interface
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

/// Network information implementation using connectivity_plus
@LazySingleton(as: NetworkInfo)
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return connectivity.onConnectivityChanged.map(
      (result) => !result.contains(ConnectivityResult.none),
    );
  }
}
