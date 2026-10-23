import 'dart:async';

import 'package:cunehat/features/forecast/data/forecast_service.dart';
import 'package:cunehat/features/forecast/presentation/bloc/forecast_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = DateTime(2026, 11, 10, 15);
final _november =
    DateTimeRange(start: DateTime(2026, 11, 1), end: DateTime(2026, 11, 30));

/// Servise giden ufku kaydeder.
class _RecordingService extends Fake implements ForecastService {
  final horizons = <int>[];

  @override
  Future<ForecastResult> forecast({
    required String? userId,
    required DateTimeRange period,
    DateTimeRange? previousPeriod,
    DateTime? today,
    int horizonDays = 30,
    String? walletId,
  }) async {
    horizons.add(horizonDays);
    return const ForecastResult(wallets: {}, categories: []);
  }
}

void main() {
  late _RecordingService service;
  late DateTime horizon;
  late StreamController<Object?> unitChanges;

  ForecastCubit build() {
    final cubit = ForecastCubit(
      service,
      userId: 'u',
      periodOf: () => _november,
      horizonEndOf: (_) => horizon,
      horizonChanges: unitChanges.stream,
      clock: () => _today,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    service = _RecordingService();
    horizon = DateTime(2026, 11, 30);
    unitChanges = StreamController<Object?>.broadcast();
    addTearDown(unitChanges.close);
  });

  test('ufuk (dönem sonu) motora gün olarak gider ve durumda saklanır',
      () async {
    final cubit = build();
    await cubit.load();
    expect(service.horizons, [20]);
    expect(cubit.state.horizonEnd, DateTime(2026, 11, 30));
    expect(cubit.state.revealed, isFalse);
  });

  test(
      'dönem birimi değişince YALNIZ ufuk değiştiyse yeniden hesaplar '
      '(Ayarlar sayfa açıkken üstüne itilir)', () async {
    final cubit = build();
    await cubit.load();

    unitChanges.add(null); // aynı ufuk
    await settle();
    expect(service.horizons, [20]);

    horizon = DateTime(2026, 11, 15); // haftalığa geçildi
    unitChanges.add(null);
    await settle();
    expect(service.horizons, [20, 5]);
    expect(cubit.state.horizonEnd, DateTime(2026, 11, 15));
  });

  group('bildirimden açılış (reveal)', () {
    test('ilk yüklemeyi yapar; ufuk bildirimin gününe uzar, tahmin görünür',
        () async {
      horizon = DateTime(2026, 11, 15);
      final cubit = build()..reveal(until: DateTime(2026, 11, 24, 9));
      await settle();

      expect(service.horizons, [14]);
      expect(cubit.state.horizonEnd, DateTime(2026, 11, 24));
      expect(cubit.state.revealed, isTrue);
    });

    test('bildirimin günü ufkun içindeyse ufuk kısalmaz', () async {
      final cubit = build()..reveal(until: DateTime(2026, 11, 12));
      await settle();
      expect(service.horizons, [20]);
      expect(cubit.state.horizonEnd, DateTime(2026, 11, 30));
    });

    test(
        'sayfa açıkken gelen istek yeniden hesaplatır ama gerekmiyorsa '
        'tekrar yüklemez', () async {
      horizon = DateTime(2026, 11, 15);
      final cubit = build();
      await cubit.load();

      cubit.reveal();
      await settle();
      expect(service.horizons, [5], reason: 'günsüz istek ufku değiştirmez');
      expect(cubit.state.revealed, isTrue);

      cubit.reveal(until: DateTime(2026, 11, 20));
      await settle();
      expect(service.horizons, [5, 10]);
    });

    test('anahtar kapatılınca tahmin biter, uzamış ufuk kalır', () async {
      horizon = DateTime(2026, 11, 15);
      final cubit = build()..reveal(until: DateTime(2026, 11, 20));
      await settle();

      cubit.endReveal();
      expect(cubit.state.revealed, isFalse);
      expect(cubit.state.horizonEnd, DateTime(2026, 11, 20));
      cubit.refreshIfStale();
      await settle();
      expect(service.horizons, [10]);
    });

    test('ufuk motorun tavanını aşmaz', () async {
      final cubit = build()..reveal(until: DateTime(2027, 6, 1));
      await settle();
      expect(service.horizons, [ForecastCubit.maxHorizonDays]);
      expect(cubit.state.horizonEnd, DateTime(2027, 3, 10));
    });
  });
}
