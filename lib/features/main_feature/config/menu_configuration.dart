import 'package:flutter/material.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

/// Configuration for menu items
///
/// SubMenuConfig now uses viewIndex instead of HomeSubView enum
/// View index mapping:
/// - Index 0: MainView
/// - Index 1+: SubViews (1, 2, 3, etc.)
class MenuConfiguration {
  final SliderState sliderState;
  final List<SubMenuConfig> subMenus;
  final List<MiniButtonConfig> miniButtons;

  const MenuConfiguration({
    required this.sliderState,
    required this.subMenus,
    required this.miniButtons,
  });
}

/// Configuration for a submenu item
///
/// [viewIndex] is 1-based (0 is main view, so submenu starts from 1)
class SubMenuConfig {
  final String label;
  final IconData icon;
  final int viewIndex;

  const SubMenuConfig({
    required this.label,
    required this.icon,
    required this.viewIndex,
  });
}

/// Configuration for a mini button
class MiniButtonConfig {
  final String label;
  final IconData icon;
  final String actionType;

  const MiniButtonConfig({
    required this.label,
    required this.icon,
    required this.actionType,
  });
}

/// Predefined menu configurations
class MenuConfigs {
  const MenuConfigs._();

  static const Map<SliderState, MenuConfiguration> _configs = {
    SliderState.savedMoney: MenuConfiguration(
      sliderState: SliderState.savedMoney,
      miniButtons: [
        MiniButtonConfig(
          label: 'Altın',
          icon: Icons.monetization_on,
          actionType: 'add_gold_investment',
        ),
        MiniButtonConfig(
          label: 'Hisse',
          icon: Icons.trending_up,
          actionType: 'add_stock_investment',
        ),
        MiniButtonConfig(
          label: 'Özel',
          icon: Icons.account_balance_wallet,
          actionType: 'add_custom_investment',
        ),
      ],
      subMenus: [
        SubMenuConfig(
          label: 'Detay',
          icon: Icons.pie_chart,
          viewIndex: 1, // First subview
        ),
      ],
    ),
    SliderState.transactions: MenuConfiguration(
      sliderState: SliderState.transactions,
      miniButtons: [
        MiniButtonConfig(
          label: 'Gelir',
          icon: Icons.arrow_circle_up,
          actionType: 'add_income',
        ),
        MiniButtonConfig(
          label: 'Gider',
          icon: Icons.arrow_circle_down,
          actionType: 'add_expense',
        ),
      ],
      subMenus: [
        SubMenuConfig(
          label: 'Detay',
          icon: Icons.insights,
          viewIndex: 1,
        ),
        SubMenuConfig(
          label: 'Rapor',
          icon: Icons.analytics,
          viewIndex: 2,
        ),
        SubMenuConfig(
          label: 'Bekleyen',
          icon: Icons.pending_actions,
          viewIndex: 3,
        ),
      ],
    ),
    SliderState.debt: MenuConfiguration(
      sliderState: SliderState.debt,
      miniButtons: [
        MiniButtonConfig(
          label: 'Alacak',
          icon: Icons.trending_up,
          actionType: 'add_receivable',
        ),
        MiniButtonConfig(
          label: 'Borç',
          icon: Icons.trending_down,
          actionType: 'add_debt',
        ),
      ],
      subMenus: [
        SubMenuConfig(
          label: 'Geçmiş',
          icon: Icons.history,
          viewIndex: 1,
        ),
      ],
    ),
  };

  static Map<SliderState, MenuConfiguration> get allConfigs =>
      Map.unmodifiable(_configs);

  static Map<SliderState, MenuConfiguration> get configs => allConfigs;
}
