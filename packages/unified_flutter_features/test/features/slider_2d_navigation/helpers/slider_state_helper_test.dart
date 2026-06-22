import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/core/constants/app_colors.dart';
import 'package:unified_flutter_features/core/texts/slider_texts.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/helpers/slider_state_helper.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

void main() {
  group('getStateFromValue', () {
    test('returns first state when totalStates <= 1', () {
      expect(
          SliderStateHelper.getStateFromValue(0.0, 1), SliderState.savedMoney);
      expect(
          SliderStateHelper.getStateFromValue(0.5, 1), SliderState.savedMoney);
      expect(
          SliderStateHelper.getStateFromValue(1.0, 0), SliderState.savedMoney);
    });

    test('returns savedMoney at value 0.0 for 3 states', () {
      expect(
          SliderStateHelper.getStateFromValue(0.0, 3), SliderState.savedMoney);
    });

    test('returns debt at value 1.0 for 3 states', () {
      expect(SliderStateHelper.getStateFromValue(1.0, 3), SliderState.debt);
    });

    test('returns transactions at value 0.5 for 3 states', () {
      expect(SliderStateHelper.getStateFromValue(0.5, 3),
          SliderState.transactions);
    });

    test('transitions around boundaries for 3 states', () {
      expect(
          SliderStateHelper.getStateFromValue(0.24, 3), SliderState.savedMoney);
      expect(SliderStateHelper.getStateFromValue(0.26, 3),
          SliderState.transactions);
      expect(SliderStateHelper.getStateFromValue(0.74, 3),
          SliderState.transactions);
      expect(SliderStateHelper.getStateFromValue(0.76, 3), SliderState.debt);
    });

    test('works for 2 states (on/off)', () {
      expect(
          SliderStateHelper.getStateFromValue(0.0, 2), SliderState.savedMoney);
      expect(
          SliderStateHelper.getStateFromValue(0.49, 2), SliderState.savedMoney);
      expect(SliderStateHelper.getStateFromValue(0.5, 2),
          SliderState.transactions);
      expect(SliderStateHelper.getStateFromValue(1.0, 2),
          SliderState.transactions);
    });

    test('clamps value out of bounds', () {
      expect(
          SliderStateHelper.getStateFromValue(-0.5, 3), SliderState.savedMoney);
      expect(SliderStateHelper.getStateFromValue(1.5, 3), SliderState.debt);
    });
  });

  group('getTargetValue', () {
    test('returns 0.0 when totalStates <= 1', () {
      expect(SliderStateHelper.getTargetValue(SliderState.savedMoney, 1), 0.0);
      expect(SliderStateHelper.getTargetValue(SliderState.debt, 0), 0.0);
    });

    test('returns 0.0 for savedMoney at 3 states', () {
      expect(SliderStateHelper.getTargetValue(SliderState.savedMoney, 3), 0.0);
    });

    test('returns 0.5 for transactions at 3 states', () {
      expect(
          SliderStateHelper.getTargetValue(SliderState.transactions, 3), 0.5);
    });

    test('returns 1.0 for debt at 3 states', () {
      expect(SliderStateHelper.getTargetValue(SliderState.debt, 3), 1.0);
    });

    test('is consistent with getStateFromValue', () {
      for (final state in SliderState.values) {
        final target = SliderStateHelper.getTargetValue(state, 3);
        final back = SliderStateHelper.getStateFromValue(target, 3);
        expect(back, state);
      }
    });
  });

  group('getColorForState', () {
    test('returns correct colors', () {
      expect(SliderStateHelper.getColorForState(SliderState.savedMoney),
          AppColors.sliderSuccess);
      expect(SliderStateHelper.getColorForState(SliderState.transactions),
          AppColors.sliderInfo);
      expect(SliderStateHelper.getColorForState(SliderState.debt),
          AppColors.sliderError);
    });
  });

  group('getLabelForState', () {
    test('returns correct labels', () {
      const texts = SliderTexts();
      expect(SliderStateHelper.getLabelForState(SliderState.savedMoney, texts),
          texts.savings);
      expect(
          SliderStateHelper.getLabelForState(SliderState.transactions, texts),
          texts.transactions);
      expect(SliderStateHelper.getLabelForState(SliderState.debt, texts),
          texts.debt);
    });
  });

  group('getIconForState', () {
    test('returns correct icons', () {
      expect(SliderStateHelper.getIconForState(SliderState.savedMoney),
          Icons.savings_outlined);
      expect(SliderStateHelper.getIconForState(SliderState.transactions),
          Icons.swap_horiz_rounded);
      expect(SliderStateHelper.getIconForState(SliderState.debt),
          Icons.account_balance_wallet_outlined);
    });
  });
}
