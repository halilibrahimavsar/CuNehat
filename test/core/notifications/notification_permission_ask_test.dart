import 'package:cunehat/core/notifications/notification_permission_dialog.dart';
import 'package:cunehat/features/settings/presentation/page/privacy_policy_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bildirim izni ne zaman sorulur', () {
    test(
        'hatırlatılacak kayıt yokken SORULMAZ (eskiden ilk açılışta soruluyordu)',
        () {
      expect(
        shouldAskNotificationPermission(
          alreadyExplained: false,
          reminderWanted: false,
        ),
        isFalse,
      );
    });

    test('hatırlatma taşıyan ilk kayıt oluşunca sorulur', () {
      expect(
        shouldAskNotificationPermission(
          alreadyExplained: false,
          reminderWanted: true,
        ),
        isTrue,
      );
    });

    test('bir kez sorulduysa yeni kayıtlar yeniden sordurmaz', () {
      expect(
        shouldAskNotificationPermission(
          alreadyExplained: true,
          reminderWanted: true,
        ),
        isFalse,
      );
    });
  });

  // Bu anahtarlar eski kurulumların tercihlerinde YAZILI. Değişirlerse
  // testerlara bildirim gerekçesi yeniden sorulur.
  group('kalıcı bayrak anahtarları değişmez', () {
    test('bildirim gerekçesi', () {
      expect(
        kNotificationRationaleShownKey,
        'notification_permission_explained',
      );
    });

    test('gizlilik notu', () {
      expect(kPrivacyConsentShownKey, 'privacy_consent_shown');
    });
  });
}
