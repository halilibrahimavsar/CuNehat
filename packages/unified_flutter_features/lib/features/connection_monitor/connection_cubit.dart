import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:unified_flutter_features/core/texts/connection_texts.dart';
import 'connection_state.dart';

/// A BLoC/Cubit that monitors internet connectivity status using connectivity_plus.
///
/// Example usage:
/// ```dart
/// BlocProvider(
///   create: (_) => ConnectionCubit(),
///   child: BlocBuilder<ConnectionCubit, ConnectionMonitorState>(
///     builder: (context, state) {
///       return DefaultConnectionIndicator(connectionState: state);
///     },
///   ),
/// )
/// ```
class ConnectionCubit extends Cubit<ConnectionMonitorState> {
  final Connectivity _connectivity;
  final ConnectionTexts texts;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  /// Creates a [ConnectionCubit] instance.
  ///
  /// [connectivity] Optional connectivity instance for testing.
  ConnectionCubit({
    Connectivity? connectivity,
    this.texts = const ConnectionTexts(),
  })  : _connectivity = connectivity ?? Connectivity(),
        super(const ConnectionMonitorState(status: ConnectionStatus.checking)) {
    _initializeConnectionCheck();
  }

  void _initializeConnectionCheck() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      _handleConnectivityChange(results);
    });

    checkInitialConnection();
  }

  Future<void> checkInitialConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      emit(
        state.copyWith(
          status: ConnectionStatus.disconnected,
          message: '${texts.checkFailedPrefix}: ${e.toString()}',
          lastChecked: DateTime.now(),
        ),
      );
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (hasConnection) {
      emit(
        state.copyWith(
          status: ConnectionStatus.connected,
          message: texts.connectedMessage,
          lastChecked: DateTime.now(),
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: ConnectionStatus.disconnected,
          message: texts.disconnectedMessage,
          lastChecked: DateTime.now(),
        ),
      );
    }
  }

  /// Manually triggers a connection check.
  ///
  /// Sets status to [ConnectionStatus.checking] first, then performs the check.
  Future<void> manualCheck() async {
    emit(
      state.copyWith(
        status: ConnectionStatus.checking,
        message: texts.checkingMessage,
      ),
    );
    await checkInitialConnection();
  }

  /// Converts connectivity results to a human-readable string.
  ///
  /// [results] List of connectivity results to convert.
  /// Returns a comma-separated string of connection types.
  String getConnectionTypeString(List<ConnectivityResult> results) {
    if (results.isEmpty) return texts.unknownConnectionType;

    final types = <String>[];
    for (final result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
          types.add(texts.typeWifi);
          break;
        case ConnectivityResult.ethernet:
          types.add(texts.typeEthernet);
          break;
        case ConnectivityResult.mobile:
          types.add(texts.typeMobile);
          break;
        case ConnectivityResult.bluetooth:
          types.add(texts.typeBluetooth);
          break;
        case ConnectivityResult.vpn:
          types.add(texts.typeVpn);
          break;
        case ConnectivityResult.other:
          types.add(texts.typeOther);
          break;
        case ConnectivityResult.none:
          types.add(texts.typeNone);
          break;
      }
    }

    return types.join(', ');
  }

  @override
  Future<void> close() {
    _connectivitySubscription.cancel();
    return super.close();
  }
}
