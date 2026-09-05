import 'dart:async';

import 'package:cunehat/core/services/system_activity_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SystemActivityGuard', () {
    test('hiçbir şey açılmadıysa duraklama affedilmez', () {
      expect(SystemActivityGuard().shouldForgivePause(), isFalse);
    });

    test('etkinlik AÇIKKEN duraklama affedilir', () async {
      final guard = SystemActivityGuard();
      final gate = Completer<void>();

      final running = guard.run(() => gate.future);
      expect(guard.isActive, isTrue);
      expect(guard.shouldForgivePause(), isTrue);

      gate.complete();
      await running;
    });

    test('etkinlik bittikten hemen sonraki duraklama da affedilir', () async {
      // Android `onActivityResult`ı `onResume`dan önce çağırır ama seçicinin
      // sonucu Dart'a asenkron ulaşır: `resumed` bildirimi run()'ın Future'ı
      // tamamlandıktan SONRA gelebilir. Bu pencere olmasaydı yarışın yarısında
      // kilit yine düşerdi.
      final guard = SystemActivityGuard();
      await guard.run(() async {});

      expect(guard.isActive, isFalse);
      expect(guard.shouldForgivePause(), isTrue);
    });

    test('af penceresi dolunca duraklama artık affedilmez', () async {
      var clock = DateTime(2026, 9, 3, 12);
      final guard = SystemActivityGuard.withClock(() => clock);
      await guard.run(() async {});

      clock = clock.add(
        SystemActivityGuard.returnGrace + const Duration(seconds: 1),
      );
      expect(guard.shouldForgivePause(), isFalse);
    });

    test('iç içe etkinlikte sayaç erken sıfırlanmaz', () async {
      final guard = SystemActivityGuard();
      final inner = Completer<void>();
      final outer = Completer<void>();

      final a = guard.run(() => outer.future);
      final b = guard.run(() => inner.future);

      inner.complete();
      await b;
      // Dıştaki hâlâ açık.
      expect(guard.isActive, isTrue);

      outer.complete();
      await a;
      expect(guard.isActive, isFalse);
    });

    test('etkinlik patlarsa bayrak asılı kalmaz', () async {
      var clock = DateTime(2026, 9, 3, 12);
      final guard = SystemActivityGuard.withClock(() => clock);

      await expectLater(
        guard.run(() async => throw StateError('seçici patladı')),
        throwsStateError,
      );

      expect(guard.isActive, isFalse);
      clock = clock.add(
        SystemActivityGuard.returnGrace + const Duration(seconds: 1),
      );
      expect(guard.shouldForgivePause(), isFalse);
    });
  });
}
