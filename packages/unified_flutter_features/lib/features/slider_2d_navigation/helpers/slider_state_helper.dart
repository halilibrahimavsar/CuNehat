import 'package:flutter/material.dart';
import 'package:unified_flutter_features/core/constants/app_colors.dart';
import '../models/slider_models.dart';

class SliderStateHelper {
  static SliderState getStateFromValue(double value, int totalStates) {
    if (totalStates <= 1) return SliderState.values.first;

    final segmentSize = 1.0 / (totalStates - 1);
    final maxIndex = (totalStates - 1).clamp(0, SliderState.values.length - 1);
    final index = (value / segmentSize).round().clamp(0, maxIndex);
    return SliderState.values[index];
  }

  static Color getColorForState(SliderState state) {
    switch (state) {
      case SliderState.savedMoney:
        return AppColors.sliderSuccess;
      case SliderState.transactions:
        return AppColors.sliderInfo;
      case SliderState.debt:
        return AppColors.sliderError;
    }
  }

  static String getLabelForState(SliderState state) {
    switch (state) {
      case SliderState.savedMoney:
        return 'SAVINGS';
      case SliderState.transactions:
        return 'TRANSACTIONS';
      case SliderState.debt:
        return 'DEBT';
    }
  }

  static IconData getIconForState(SliderState state) {
    switch (state) {
      case SliderState.savedMoney:
        return Icons.savings_outlined;
      case SliderState.transactions:
        return Icons.swap_horiz_rounded;
      case SliderState.debt:
        return Icons.account_balance_wallet_outlined;
    }
  }

  static double getTargetValue(SliderState state, int totalStates) {
    if (totalStates <= 1) return 0.0;
    final index = SliderState.values.indexOf(state);
    return index / (totalStates - 1);
  }
}
