import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/constants/slider_config.dart';

void main() {
  group('SliderConfig dimensions', () {
    test('knob fits within slider', () {
      expect(SliderConfig.knobHeight, lessThan(SliderConfig.sliderHeight));
    });

    test('etiket stili açık satır yüksekliği taşır', () {
      // Taşımadığında Material 3'ün bodyMedium'undan height: 1.43 miras
      // alınıyor ve 16 px'lik punto 23 px'lik satır kutusu üretiyordu.
      expect(
          SliderConfig.knobLabelStyle.height, SliderConfig.knobLabelLineHeight);
    });

    test('mini button size is positive', () {
      expect(SliderConfig.miniButtonSize, greaterThan(0));
    });

    test('transition threshold is within range', () {
      expect(SliderConfig.transitionThresholdLow, greaterThan(0));
      expect(SliderConfig.transitionThresholdLow, lessThan(1));
    });
  });
}
