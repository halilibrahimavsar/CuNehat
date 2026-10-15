import 'package:cunehat/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WalletColors.hexToColor', () {
    test('kendi biçimimizi (0xAARRGGBB) çözer ve colorToHex ile gidip gelir',
        () {
      const red = Color(0xFFF44336);
      expect(WalletColors.colorToHex(red), '0xFFF44336');
      expect(WalletColors.hexToColor('0xFFF44336'), red);
      expect(WalletColors.hexToColor(WalletColors.colorToHex(red)), red);
    });

    test('yedekte elle yazılmış biçimleri de çözer (smoke test)', () {
      const red = Color(0xFFF44336);
      expect(WalletColors.hexToColor('FFF44336'), red);
      expect(WalletColors.hexToColor('#F44336'), red);
      expect(WalletColors.hexToColor('F44336'), red);
      expect(WalletColors.hexToColor(' 0xfff44336 '), red);
      expect(WalletColors.hexToColor('#80F44336'), const Color(0x80F44336));
    });

    test('çözülemeyen değerde FIRLATMAZ, ilk hazır renge düşer', () {
      for (final bad in ['', 'kırmızı', '0xZZ', '12345', '0x1234567890']) {
        expect(WalletColors.hexToColor(bad), WalletColors.presetColors.first,
            reason: bad);
      }
    });
  });
}
