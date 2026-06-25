import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

void main() {
  group('SliderState', () {
    test('has three values in order', () {
      expect(SliderState.values, hasLength(3));
      expect(SliderState.values[0], SliderState.savedMoney);
      expect(SliderState.values[1], SliderState.transactions);
      expect(SliderState.values[2], SliderState.debt);
    });
  });

  group('MiniButtonData', () {
    test('stores all fields', () {
      void onTap() {}
      final data = MiniButtonData(
        icon: Icons.star,
        label: 'Test',
        color: Colors.red,
        onTap: onTap,
      );
      expect(data.icon, Icons.star);
      expect(data.label, 'Test');
      expect(data.color, Colors.red);
      expect(data.onTap, onTap);
    });
  });

  group('SubMenuItem', () {
    test('stores all fields with defaults', () {
      void onTap() {}
      final item = SubMenuItem(
        icon: Icons.add,
        label: 'Add',
        onTap: onTap,
      );
      expect(item.icon, Icons.add);
      expect(item.label, 'Add');
      expect(item.onTap, onTap);
      expect(item.isDefault, false);
      expect(item.isMainTitle, false);
    });

    test('accepts explicit boolean flags', () {
      void onTap() {}
      final item = SubMenuItem(
        icon: Icons.settings,
        label: 'Settings',
        onTap: onTap,
        isDefault: true,
        isMainTitle: true,
      );
      expect(item.isDefault, true);
      expect(item.isMainTitle, true);
    });
  });
}
