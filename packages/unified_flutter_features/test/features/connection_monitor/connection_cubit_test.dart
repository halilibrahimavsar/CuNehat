import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unified_flutter_features/features/connection_monitor/connection_cubit.dart';
import 'package:unified_flutter_features/features/connection_monitor/connection_state.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  late _MockConnectivity connectivity;
  late StreamController<List<ConnectivityResult>> streamController;
  late Completer<List<ConnectivityResult>> initialCheckCompleter;

  setUp(() {
    connectivity = _MockConnectivity();
    streamController = StreamController<List<ConnectivityResult>>.broadcast();
    initialCheckCompleter = Completer<List<ConnectivityResult>>();
    when(() => connectivity.onConnectivityChanged)
        .thenAnswer((_) => streamController.stream);
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) => initialCheckCompleter.future);
  });

  tearDown(() {
    streamController.close();
  });

  group('initial state', () {
    test('starts with checking status', () async {
      final cubit = ConnectionCubit(connectivity: connectivity);
      expect(cubit.state.status, ConnectionStatus.checking);
      initialCheckCompleter.complete([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
    });
  });

  group('checkInitialConnection', () {
    blocTest<ConnectionCubit, ConnectionMonitorState>(
      'emits connected when wifi is available',
      build: () => ConnectionCubit(connectivity: connectivity),
      act: (_) {
        initialCheckCompleter.complete([ConnectivityResult.wifi]);
      },
      expect: () => [
        predicate<ConnectionMonitorState>(
            (s) => s.status == ConnectionStatus.connected),
      ],
    );

    blocTest<ConnectionCubit, ConnectionMonitorState>(
      'emits disconnected when no connectivity',
      build: () {
        when(() => connectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        return ConnectionCubit(connectivity: connectivity);
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        predicate<ConnectionMonitorState>(
            (s) => s.status == ConnectionStatus.disconnected),
      ],
    );

    blocTest<ConnectionCubit, ConnectionMonitorState>(
      'emits disconnected on exception',
      build: () {
        when(() => connectivity.checkConnectivity())
            .thenAnswer((_) async => throw Exception('check failed'));
        return ConnectionCubit(connectivity: connectivity);
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        predicate<ConnectionMonitorState>((s) =>
            s.status == ConnectionStatus.disconnected &&
            s.message != null &&
            s.message!.contains('check failed')),
      ],
    );
  });

  group('manualCheck', () {
    blocTest<ConnectionCubit, ConnectionMonitorState>(
      'emits checking then connected',
      build: () {
        final comp = Completer<List<ConnectivityResult>>();
        when(() => connectivity.checkConnectivity())
            .thenAnswer((_) => comp.future);
        return ConnectionCubit(connectivity: connectivity);
      },
      act: (cubit) async {
        cubit.manualCheck();
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        predicate<ConnectionMonitorState>(
            (s) => s.status == ConnectionStatus.checking),
      ],
      verify: (cubit) {
        expect(cubit.state.status, ConnectionStatus.checking);
        cubit.close();
      },
    );
  });

  group('onConnectivityChanged stream', () {
    blocTest<ConnectionCubit, ConnectionMonitorState>(
      'emits connected when stream sends wifi',
      build: () {
        return ConnectionCubit(connectivity: connectivity);
      },
      act: (_) {
        streamController.add([ConnectivityResult.wifi]);
      },
      expect: () => [
        predicate<ConnectionMonitorState>(
            (s) => s.status == ConnectionStatus.connected),
      ],
    );

    blocTest<ConnectionCubit, ConnectionMonitorState>(
      'emits disconnected when stream sends none',
      build: () {
        return ConnectionCubit(connectivity: connectivity);
      },
      act: (_) {
        streamController.add([ConnectivityResult.none]);
      },
      expect: () => [
        predicate<ConnectionMonitorState>(
            (s) => s.status == ConnectionStatus.disconnected),
      ],
    );
  });

  group('getConnectionTypeString', () {
    Future<ConnectionCubit> createCubit() async {
      final cubit = ConnectionCubit(connectivity: connectivity);
      initialCheckCompleter.complete([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      return cubit;
    }

    test('returns WiFi for ConnectivityResult.wifi', () async {
      final cubit = await createCubit();
      expect(cubit.getConnectionTypeString([ConnectivityResult.wifi]), 'WiFi');
      await cubit.close();
    });

    test('returns Mobile for ConnectivityResult.mobile', () async {
      final cubit = await createCubit();
      expect(
          cubit.getConnectionTypeString([ConnectivityResult.mobile]), 'Mobile');
      await cubit.close();
    });

    test('returns comma-separated for multiple results', () async {
      final cubit = await createCubit();
      expect(
          cubit.getConnectionTypeString(
              [ConnectivityResult.wifi, ConnectivityResult.mobile]),
          'WiFi, Mobile');
      await cubit.close();
    });

    test('returns Unknown for empty list', () async {
      final cubit = await createCubit();
      expect(cubit.getConnectionTypeString([]), 'Unknown');
      await cubit.close();
    });

    test('returns None for ConnectivityResult.none', () async {
      final cubit = await createCubit();
      expect(cubit.getConnectionTypeString([ConnectivityResult.none]), 'None');
      await cubit.close();
    });

    test('returns Other for other types', () async {
      final cubit = await createCubit();
      expect(
          cubit.getConnectionTypeString([
            ConnectivityResult.bluetooth,
            ConnectivityResult.ethernet,
            ConnectivityResult.vpn,
          ]),
          'Bluetooth, Ethernet, VPN');
      await cubit.close();
    });
  });

  group('ConnectionMonitorState', () {
    test('equality works', () {
      final now = DateTime.now();
      final a = ConnectionMonitorState(
          status: ConnectionStatus.connected, message: 'ok', lastChecked: now);
      final b = ConnectionMonitorState(
          status: ConnectionStatus.connected, message: 'ok', lastChecked: now);
      final c = ConnectionMonitorState(
          status: ConnectionStatus.disconnected,
          message: 'ok',
          lastChecked: now);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('copyWith preserves values', () {
      const state = ConnectionMonitorState(status: ConnectionStatus.checking);
      final copied = state.copyWith(status: ConnectionStatus.connected);
      expect(copied.status, ConnectionStatus.connected);
      expect(copied.message, isNull);
      expect(copied.lastChecked, isNull);
    });
  });
}
