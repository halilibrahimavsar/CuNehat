import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_time_axis.dart';
import 'package:flutter_test/flutter_test.dart';

/// Alt eksen etiketlerinin seyreltilmesi. Bu olmadan grafikler her noktaya
/// tarih basıyordu ve 30 günlük veride yazılar üst üste biniyordu.
void main() {
  group('dateLabelStep', () {
    test('hepsi sığıyorsa her noktaya etiket (step 1)', () {
      expect(
        dateLabelStep(pointCount: 5, availableWidth: 5 * kDateLabelSlot),
        1,
      );
    });

    test('sığmıyorsa seyreltir', () {
      // 30 nokta, ~6 etiketlik yer → 5'te bir.
      final step =
          dateLabelStep(pointCount: 30, availableWidth: 6 * kDateLabelSlot);
      expect(step, 5);
      // Gerçekten sığdığını doğrula: basılan etiket sayısı × slot ≤ genişlik.
      final drawn = (30 / step).ceil();
      expect(drawn * kDateLabelSlot, lessThanOrEqualTo(6 * kDateLabelSlot));
    });

    test('tek nokta ve boş seri güvenli', () {
      expect(dateLabelStep(pointCount: 1, availableWidth: 10), 1);
      expect(dateLabelStep(pointCount: 0, availableWidth: 10), 1);
    });

    test('genişlik tek etiketi bile almıyorsa yalnız ilk etiket kalır', () {
      // step == pointCount ⇒ index % step == 0 sadece 0'da doğru.
      expect(dateLabelStep(pointCount: 20, availableWidth: 10), 20);
    });

    test('sınırsız genişlikte patlamaz (.floor() sonsuzda hata verir)', () {
      expect(dateLabelStep(pointCount: 30, availableWidth: double.infinity), 1);
    });

    test('dönen adım her zaman ≥ 1 (sıfıra bölme / görünmez eksen yok)', () {
      for (var n = 1; n <= 60; n++) {
        for (final w in [0.0, 30.0, 200.0, 900.0]) {
          expect(dateLabelStep(pointCount: n, availableWidth: w),
              greaterThanOrEqualTo(1));
        }
      }
    });
  });
}
