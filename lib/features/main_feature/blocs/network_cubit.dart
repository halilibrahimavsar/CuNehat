import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../widgets/network/network_info.dart';

@injectable
class NetworkCubit extends Cubit<NetworkState> {
  final NetworkInfo _networkInfo;

  NetworkCubit(this._networkInfo) : super(const NetworkState.initial()) {
    _initializeNetworkMonitoring();
  }

  void _initializeNetworkMonitoring() {
    // Check initial connection status
    _checkConnection();

    // Listen to connectivity changes
    _networkInfo.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        emit(const NetworkState.connected());
      } else {
        emit(const NetworkState.disconnected());
      }
    });
  }

  Future<void> _checkConnection() async {
    emit(const NetworkState.checking());
    final isConnected = await _networkInfo.isConnected;
    if (isConnected) {
      emit(const NetworkState.connected());
    } else {
      emit(const NetworkState.disconnected());
    }
  }

  Future<void> refreshConnection() async {
    await _checkConnection();
  }
}

sealed class NetworkState {
  const NetworkState();

  const factory NetworkState.initial() = Initial;
  const factory NetworkState.checking() = Checking;
  const factory NetworkState.connected() = Connected;
  const factory NetworkState.disconnected() = Disconnected;
}

class Initial extends NetworkState {
  const Initial();
}

class Checking extends NetworkState {
  const Checking();
}

class Connected extends NetworkState {
  const Connected();
}

class Disconnected extends NetworkState {
  const Disconnected();
}
