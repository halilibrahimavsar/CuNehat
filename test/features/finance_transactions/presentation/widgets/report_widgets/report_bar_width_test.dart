import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_bar_width.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('küçük pay görünür tabana yükseltilir', () {
    expect(visibleBarWidth(maxWidth: 200, fraction: 0.001), 4.0);
  });

  test('pay genişliği orantılı ölçekler', () {
    expect(visibleBarWidth(maxWidth: 200, fraction: 0.5), 100.0);
  });

  // Eskiden `clamp(4, maxWidth)` dar yerleşimde ArgumentError fırlatıyordu ve
  // kart build sırasında hata görünümüne düşüyordu.
  test('taban genişlikten büyükse fırlatmaz, genişliğe kırpılır', () {
    expect(visibleBarWidth(maxWidth: 2, fraction: 0.01), 2.0);
    expect(visibleBarWidth(maxWidth: 0, fraction: 0), 0.0);
  });

  test('alt kategori çubuğu kendi tabanını kullanır', () {
    expect(visibleBarWidth(maxWidth: 200, fraction: 0, minVisible: 3), 3.0);
  });
}
