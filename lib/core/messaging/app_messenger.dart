import 'package:flutter/material.dart';

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';

/// Uygulamanın TEK kısa mesaj (snackbar) yolu.
///
/// Neden global anahtar üzerinden, `BuildContext` almadan:
/// `ScaffoldMessenger.of(context)` çağıran widget ağaçtan düştüğü anda
/// "Looking up a deactivated widget's ancestor is unsafe" atıyor. Mesajlar
/// tam da async bir işin bitiminde — yani widget'ın ölmüş olabileceği anda —
/// gösteriliyor, bu yüzden her çağıran kendi `mounted` kapısını doğru
/// kurmak zorunda kalıyordu. Anahtar `MaterialApp.router`'a bağlı olduğundan
/// mesaj kaynağının yaşam döngüsünden bağımsızdır.
///
/// Konum bilinçli olarak HER ZAMAN alt: floating snackbar'ın yerleşimi o an
/// ekrandaki Scaffold'un geometrisine bağlıdır, dolayısıyla "üstte göster"
/// ancak ekran yüksekliği kadar alt boşluk vererek taklit edilebilir — ve
/// iç route/sheet/klavye durumlarında taşıp görünmez snackbar üretir.
/// Üstte kalıcı durum göstermek gerekirse yol `MaterialBanner` ya da sayfa
/// içi bir şerittir, snackbar değil.
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Mesajın anlamı. Renk buradan türer; ikon da tonla birlikte değişir, çünkü
/// yeşil/kırmızı ayrımı renk körlüğünde güvenilir değil — ayırt edici sinyal
/// ikon biçimi olmalı.
enum AppMessageTone { success, error, warning, info }

/// Snackbar üstündeki tek eylem (örn. "Geri al").
@immutable
class AppMessageAction {
  final String label;
  final VoidCallback onPressed;

  const AppMessageAction({required this.label, required this.onPressed});
}

typedef AppMessageHandle
    = ScaffoldFeatureController<SnackBar, SnackBarClosedReason>;

abstract final class AppMessenger {
  /// Bilgi/başarı: okunup geçilecek kadar.
  static const Duration shortDuration = Duration(seconds: 3);

  /// Hata/uyarı: kullanıcı ne olduğunu anlamak için duraklar.
  static const Duration longDuration = Duration(seconds: 5);

  /// Eylemli mesaj (geri al): dokunma penceresi kasıtlı olarak daha uzun.
  static const Duration actionDuration = Duration(seconds: 6);

  static AppMessageHandle? success(
    String message, {
    AppMessageAction? action,
    Duration? duration,
  }) =>
      show(message,
          tone: AppMessageTone.success, action: action, duration: duration);

  static AppMessageHandle? error(
    String message, {
    AppMessageAction? action,
    Duration? duration,
  }) =>
      show(message,
          tone: AppMessageTone.error, action: action, duration: duration);

  static AppMessageHandle? warning(
    String message, {
    AppMessageAction? action,
    Duration? duration,
  }) =>
      show(message,
          tone: AppMessageTone.warning, action: action, duration: duration);

  static AppMessageHandle? info(
    String message, {
    AppMessageAction? action,
    Duration? duration,
  }) =>
      show(message,
          tone: AppMessageTone.info, action: action, duration: duration);

  static AppMessageHandle? show(
    String message, {
    AppMessageTone tone = AppMessageTone.info,
    AppMessageAction? action,
    Duration? duration,
  }) {
    final messenger = appMessengerKey.currentState;
    // Anahtar henüz bir MaterialApp'e bağlanmamış olabilir (açılış hata
    // ekranı, widget testleri). Mesaj kaybetmek çökmekten iyidir.
    if (messenger == null) return null;

    // Üst üste binmesin: yeni mesaj öncekini devralır.
    messenger.hideCurrentSnackBar();

    return messenger.showSnackBar(
      SnackBar(
        content: _AppMessageContent(
          message: message,
          tone: tone,
          action: action,
        ),
        // Görsel tamamen içerikte kuruluyor; SnackBar'ın kendi zemini
        // AppSurface dilini bozmasın.
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        duration: duration ??
            (action != null
                ? actionDuration
                : switch (tone) {
                    AppMessageTone.error => longDuration,
                    AppMessageTone.warning => longDuration,
                    AppMessageTone.success => shortDuration,
                    AppMessageTone.info => shortDuration,
                  }),
      ),
    );
  }

  static void hide() => appMessengerKey.currentState?.hideCurrentSnackBar();
}

/// Snackbar gövdesi. Tema, mesajı gösteren Scaffold'un altında çözülür —
/// yani ambiyans (light/dark) ve `AppSurface` token'ları burada geçerlidir.
/// [appMessengerKey]'in kendi context'i `MaterialApp`'ın tema katmanının
/// ÜSTÜNDE kaldığı için renkler orada okunamaz; bu widget o yüzden var.
class _AppMessageContent extends StatelessWidget {
  final String message;
  final AppMessageTone tone;
  final AppMessageAction? action;

  const _AppMessageContent({
    required this.message,
    required this.tone,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.extension<AppSurface>() ?? AppSurface.light;
    final accent = _accent(theme.colorScheme);

    // Kart yarıçapı (32) bir şerit için stadyum haline geliyor; yüzey dilini
    // koruyup snackbar ölçeğine indiriyoruz.
    final radius = BorderRadius.circular(
      surface.radius > 22 ? 22 : surface.radius,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.accentSurface(
            accent,
            surface.brightness,
            surface.accentFill,
          ),
          borderRadius: radius,
          border: Border.all(color: accent.withValues(alpha: 0.35)),
          boxShadow: surface.ambientShadow,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 12, action == null ? 14 : 6, 12),
          child: Row(
            children: [
              Icon(_icon, color: accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 6),
                TextButton(
                  onPressed: () {
                    // Eylem tetiklendi: mesajın kendisi işini bitirdi.
                    AppMessenger.hide();
                    action!.onPressed();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    action!.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _accent(ColorScheme scheme) => switch (tone) {
        // Hata rengi temadan gelir: onay diyaloglarının "danger" rengiyle
        // (ConfirmDialog → scheme.error) aynı olsun.
        AppMessageTone.error => scheme.error,
        AppMessageTone.success => AppGradients.savings,
        AppMessageTone.info => AppGradients.transactions,
        AppMessageTone.warning => const Color(0xFFF59E0B),
      };

  IconData get _icon => switch (tone) {
        AppMessageTone.success => Icons.check_circle_rounded,
        AppMessageTone.error => Icons.error_rounded,
        AppMessageTone.warning => Icons.warning_amber_rounded,
        AppMessageTone.info => Icons.info_rounded,
      };
}
