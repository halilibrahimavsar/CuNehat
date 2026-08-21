import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/helpers/drag_settle.dart';

void main() {
  group('resolveDragTarget', () {
    test('fiske yokken en yakına oturur', () {
      expect(resolveDragTarget(position: 0.4, direction: 0, maxIndex: 2), 0);
      expect(resolveDragTarget(position: 0.6, direction: 0, maxIndex: 2), 1);
      expect(resolveDragTarget(position: 1.5, direction: 0, maxIndex: 2), 2);
    });

    test('kısa yol almış hızlı fiske yine de bir adım ilerletir', () {
      // Eski davranış burada 0 döndürüyordu: fiske yutuluyordu.
      expect(resolveDragTarget(position: 0.2, direction: 1, maxIndex: 2), 1);
      expect(resolveDragTarget(position: 1.8, direction: -1, maxIndex: 2), 1);
    });

    test('fiske en fazla bir adım atar', () {
      expect(resolveDragTarget(position: 0.9, direction: 1, maxIndex: 2), 1);
      expect(resolveDragTarget(position: 1.1, direction: -1, maxIndex: 2), 1);
    });

    test('tam sayı konumdan fiske komşuya gider', () {
      expect(resolveDragTarget(position: 1.0, direction: 1, maxIndex: 2), 2);
      expect(resolveDragTarget(position: 1.0, direction: -1, maxIndex: 2), 0);
    });

    test('sınırların dışına çıkmaz', () {
      expect(resolveDragTarget(position: 2.0, direction: 1, maxIndex: 2), 2);
      expect(resolveDragTarget(position: 0.0, direction: -1, maxIndex: 2), 0);
      expect(resolveDragTarget(position: -3.0, direction: 0, maxIndex: 2), 0);
    });
  });

  group('flingDirection', () {
    test('eşik altındaki hız fiske sayılmaz', () {
      expect(flingDirection(0), 0);
      expect(flingDirection(kFlingVelocity - 1), 0);
      expect(flingDirection(-kFlingVelocity + 1), 0);
    });

    test('eşik üstündeki hız yön verir', () {
      expect(flingDirection(kFlingVelocity + 1), 1);
      expect(flingDirection(-kFlingVelocity - 1), -1);
    });
  });
}
