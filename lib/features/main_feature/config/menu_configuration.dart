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
  final MenuIconData icon;
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
  final MenuIconData icon;
  final String actionType;

  const MiniButtonConfig({
    required this.label,
    required this.icon,
    required this.actionType,
  });
}

/// Icon data for configuration
class MenuIconData {
  final int codePoint;
  final String fontFamily;

  const MenuIconData(
    this.codePoint, {
    this.fontFamily = 'MaterialIcons',
  });

  IconData toFlutterIcon() => IconData(codePoint, fontFamily: fontFamily);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuIconData &&
          runtimeType == other.runtimeType &&
          codePoint == other.codePoint &&
          fontFamily == other.fontFamily;

  @override
  int get hashCode => codePoint.hashCode ^ fontFamily.hashCode;
}

/// Predefined menu configurations
class MenuConfigs {
  const MenuConfigs._();

  static const Map<SliderState, MenuConfiguration> _configs = {
    SliderState.savedMoney: MenuConfiguration(
      sliderState: SliderState.savedMoney,
      miniButtons: [
        MiniButtonConfig(
          label: 'Yatırım',
          icon: MenuIconData(0xe553), // Icons.savings
          actionType: 'add_investment',
        ),
      ],
      subMenus: [
        SubMenuConfig(
          label: 'Detay',
          icon: MenuIconData(0xe6c4), // Icons.pie_chart
          viewIndex: 1, // First subview
        ),
      ],
    ),
    SliderState.transactions: MenuConfiguration(
      sliderState: SliderState.transactions,
      miniButtons: [
        MiniButtonConfig(
          label: 'Gelir',
          icon: MenuIconData(0xe096), // Icons.arrow_circle_up
          actionType: 'add_income',
        ),
        MiniButtonConfig(
          label: 'Gider',
          icon: MenuIconData(0xe095), // Icons.arrow_circle_down
          actionType: 'add_expense',
        ),
      ],
      subMenus: [
        SubMenuConfig(
          label: 'Detay',
          icon: MenuIconData(0xe6e6), // Icons.insights
          viewIndex: 1,
        ),
        SubMenuConfig(
          label: 'Rapor',
          icon: MenuIconData(0xe6e1), // Icons.analytics
          viewIndex: 2,
        ),
        SubMenuConfig(
          label: 'Bekleyen',
          icon: MenuIconData(0xe8df), // Icons.pending_actions
          viewIndex: 3,
        ),
      ],
    ),
    SliderState.debt: MenuConfiguration(
      sliderState: SliderState.debt,
      miniButtons: [
        MiniButtonConfig(
          label: 'Borç',
          icon: MenuIconData(0xe67d), // Icons.trending_down
          actionType: 'add_debt',
        ),
        MiniButtonConfig(
          label: 'Alacak',
          icon: MenuIconData(0xe67f), // Icons.trending_up
          actionType: 'add_receivable',
        ),
      ],
      subMenus: [
        SubMenuConfig(
          label: 'Geçmiş',
          icon: MenuIconData(0xe889), // Icons.history
          viewIndex: 1,
        ),
      ],
    ),
  };


  static Map<SliderState, MenuConfiguration> get allConfigs =>
      Map.unmodifiable(_configs);

  static Map<SliderState, MenuConfiguration> get configs => allConfigs;
}
