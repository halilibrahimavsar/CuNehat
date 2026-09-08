import 'package:cunehat/core/l10n/app_localizations.dart';
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
      expect(config.subMenus[0].label, 'Geçmiş');
      expect(config.subMenus[0].icon, Icons.history);
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
      expect(config.subMenus.length, 2);
      expect(config.subMenus[0].label, 'Detay');
      expect(config.subMenus[0].viewIndex, 1);

      expect(config.subMenus[1].label, 'Rapor');
      expect(config.subMenus[1].viewIndex, 2);
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

  group('alt menü etiketi', () {
    // REGRESYON (bildirildi 2026-09-05): "birikimin altında içgörü yazıyor
    // ama geçmiş olmalı". `label` GÖSTERİM metni değil ANAHTAR; birikim ile
    // işlemler aynı 'Detay' anahtarını paylaşıyordu ve `menuDetails` işlemler
    // sayfası için "İçgörü"ye dönüştürülünce birikim düğmesi de değişti —
    // oysa açtığı sayfa `InvestmentHistoryPage`, yani yatırım GEÇMİŞİ.
    //
    // Config'i tek başına ölçmek yetmiyordu: eski test 'Detay' anahtarını
    // doğruluyor ve YEŞİL kalıyordu. Ölçülmesi gereken anahtarın ÇÖZÜLDÜĞÜ
    // metin.
    final tr = lookupAppLocalizations(const Locale('tr'));
    final en = lookupAppLocalizations(const Locale('en'));

    String labelOf(SliderState state, {int index = 0}) => localizedSubMenuLabel(
          MenuConfigs.configs[state]!.subMenus[index].label,
          tr,
        );

    test('birikim alt menüsü "Geçmiş" yazar', () {
      expect(labelOf(SliderState.savedMoney), 'Geçmiş');
    });

    test('işlemler alt menüleri "İçgörü" ve "Rapor" yazar', () {
      expect(labelOf(SliderState.transactions), 'İçgörü');
      expect(labelOf(SliderState.transactions, index: 1), 'Rapor');
    });

    test('borç alt menüsü "Geçmiş" yazar', () {
      expect(labelOf(SliderState.debt), 'Geçmiş');
    });

    test('birikim ile işlemler AYNI metni göstermez', () {
      // İkisi farklı sayfa açıyor; aynı anahtarı paylaşmaları hatanın
      // kendisiydi.
      expect(labelOf(SliderState.savedMoney),
          isNot(labelOf(SliderState.transactions)));
    });

    test('her alt menü anahtarı gerçekten ÇEVRİLİR', () {
      // Bilinmeyen anahtar sessizce kendisini döner; İngilizce arayüzde
      // ekranda Türkçe bir anahtar görünürdü.
      for (final config in MenuConfigs.configs.values) {
        for (final sub in config.subMenus) {
          expect(localizedSubMenuLabel(sub.label, en), isNot(sub.label),
              reason: '${sub.label} için çeviri yok');
        }
      }
    });
  });
}
