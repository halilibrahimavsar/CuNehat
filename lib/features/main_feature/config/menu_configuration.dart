import 'package:flutter/material.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

import 'package:cunehat/core/l10n/app_localizations.dart';

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
          // Buradaki `label` GÖSTERİM metni değil ANAHTAR (bkz. aşağıdaki
          // 'Detay' notu). Anahtar 'Detay' idi ve `menuDetails` işlemler
          // sayfası için "İçgörü"ye dönüştürülünce birikim tarafındaki bu
          // düğme de "İçgörü" demeye başladı — oysa açtığı sayfa
          // `InvestmentDetailPage`, yani yatırım GEÇMİŞİ. Borç tarafı zaten
          // aynı anahtarı ('Geçmiş') kullanıyor.
          label: 'Geçmiş',
          icon: Icons.history,
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
          // `label` burada GÖSTERİM metni değil, ANAHTAR: ekrana yazılan ad
          // `_getLocalizedSubMenuLabel` üzerinden l10n'den gelir
          // (`menuDetails` → "İçgörü"). Anahtar Türkçe küçük harfe çevrilerek
          // eşleştiği için ASCII kalır.
          label: 'Detay',
          icon: Icons.insights,
          viewIndex: 1,
        ),
        SubMenuConfig(
          label: 'Rapor',
          icon: Icons.analytics,
          viewIndex: 2,
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

/// [SubMenuConfig.label] anahtarını ekrana yazılacak metne çevirir.
///
/// Widget'ın içinde private bir metottu; buraya taşındı çünkü asıl hata
/// anahtar ile metin arasındaki bu eşlemedeydi: `menuDetails` işlemler sayfası
/// için "İçgörü"ye dönüştürülünce, aynı anahtarı ('Detay') paylaşan birikim
/// düğmesi de "İçgörü" demeye başladı — oysa o düğme yatırım GEÇMİŞİNİ açıyor.
/// Anahtar → metin eşlemesi ancak burada, config'in yanında ölçülebiliyor.
///
/// Bilinmeyen anahtar olduğu gibi döner.
String localizedSubMenuLabel(String rawLabel, AppLocalizations l10n) {
  switch (rawLabel.toLowerCase()) {
    case 'detay':
      return l10n.menuDetails;
    case 'rapor':
      return l10n.menuReport;
    case 'geçmiş':
    case 'gecmis':
      return l10n.menuHistory;
    default:
      return rawLabel;
  }
}
