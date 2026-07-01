import 'package:cunehat/features/main_feature/config/menu_configuration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

void main() {
  group('MenuConfigs', () {
    test('contains configuration for savedMoney', () {
      final config = MenuConfigs.configs[SliderState.savedMoney];
      expect(config, isNotNull);
      expect(config!.sliderState, SliderState.savedMoney);

      // Verify mini buttons
      expect(config.miniButtons.length, 3);
      expect(config.miniButtons[0].label, 'Altın');
      expect(config.miniButtons[0].actionType, 'add_gold_investment');
      expect(config.miniButtons[0].icon, Icons.monetization_on);

      expect(config.miniButtons[1].label, 'Hisse');
      expect(config.miniButtons[1].actionType, 'add_stock_investment');
      expect(config.miniButtons[1].icon, Icons.trending_up);

      expect(config.miniButtons[2].label, 'Özel');
      expect(config.miniButtons[2].actionType, 'add_custom_investment');
      expect(config.miniButtons[2].icon, Icons.account_balance_wallet);

      // Verify submenus
      expect(config.subMenus.length, 1);
      expect(config.subMenus[0].label, 'Detay');
      expect(config.subMenus[0].icon, Icons.pie_chart);
      expect(config.subMenus[0].viewIndex, 1);
    });

    test('contains configuration for transactions', () {
      final config = MenuConfigs.configs[SliderState.transactions];
      expect(config, isNotNull);
      expect(config!.sliderState, SliderState.transactions);

      // Verify mini buttons
      expect(config.miniButtons.length, 2);
      expect(config.miniButtons[0].label, 'Gelir');
      expect(config.miniButtons[0].actionType, 'add_income');
      expect(config.miniButtons[0].icon, Icons.arrow_circle_up);

      expect(config.miniButtons[1].label, 'Gider');
      expect(config.miniButtons[1].actionType, 'add_expense');
      expect(config.miniButtons[1].icon, Icons.arrow_circle_down);

      // Verify submenus
      expect(config.subMenus.length, 3);
      expect(config.subMenus[0].label, 'Detay');
      expect(config.subMenus[0].viewIndex, 1);

      expect(config.subMenus[1].label, 'Rapor');
      expect(config.subMenus[1].viewIndex, 2);

      expect(config.subMenus[2].label, 'Bekleyen');
      expect(config.subMenus[2].viewIndex, 3);
    });

    test('contains configuration for debt', () {
      final config = MenuConfigs.configs[SliderState.debt];
      expect(config, isNotNull);
      expect(config!.sliderState, SliderState.debt);

      // Verify mini buttons
      expect(config.miniButtons.length, 2);
      expect(config.miniButtons[0].label, 'Alacak');
      expect(config.miniButtons[0].actionType, 'add_receivable');
      expect(config.miniButtons[0].icon, Icons.trending_up);

      expect(config.miniButtons[1].label, 'Borç');
      expect(config.miniButtons[1].actionType, 'add_debt');
      expect(config.miniButtons[1].icon, Icons.trending_down);

      // Verify submenus
      expect(config.subMenus.length, 1);
      expect(config.subMenus[0].label, 'Geçmiş');
      expect(config.subMenus[0].icon, Icons.history);
      expect(config.subMenus[0].viewIndex, 1);
    });
  });
}
