import 'package:cunehat/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Uygulama-içi gizlilik politikası ekranı. İçerik, barındırılan
/// `docs/privacy-policy.html` ile aynı bilgileri özetler; çevrimdışı da
/// erişilebilir olsun diye metin gömülüdür (harici bağımlılık yok).
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const String contactEmail = 'halirlnj@gmail.com';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik Politikası'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'CuNehat, finansal kayıtlarınızı takip etmenize yardımcı olan bir '
            'kişisel finans uygulamasıdır. "Önce-çevrimdışı" tasarlandı: bulut '
            'yedeklemeyi açıkça etkinleştirmediğiniz sürece verileriniz '
            'cihazınızda kalır. Sunucumuz yoktur.',
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 8),
          const _Section(
            title: 'Cihazınızda saklanan veriler',
            body:
                'Cüzdanlar, işlemler, yatırımlar, borçlar, alacaklar, bütçeler, '
                'tekrarlayan şablonlar ve uygulama tercihleri (tema, dil, '
                'kategoriler) yalnızca cihazınızda saklanır ve bize iletilmez.',
          ),
          const _Section(
            title: 'Google Drive yedeği (isteğe bağlı)',
            body:
                'Bulut yedekleme varsayılan olarak KAPALIDIR. Açarsanız Google '
                'ile oturum açılır; yalnızca e-posta adresiniz (hangi hesabın '
                'bağlı olduğunu görmeniz için) ve kısıtlı "drive.appdata" '
                'kapsamı kullanılır. Tek bir yedek dosyası (cunehat_backup.json) '
                'kendi Drive\'ınızdaki, başka uygulamaların erişemediği özel bir '
                'klasöre yazılır. Tam Drive erişimi istenmez; diğer dosyalarınız '
                'okunamaz.',
          ),
          const _Section(
            title: 'Piyasa verisi',
            body:
                'Canlı fiyat göstermek için yalnızca varlık sembolü (örn. hisse '
                'kodu) herkese açık uç noktalara (Yahoo Finance, Truncgil) '
                'gönderilir. Hiçbir kişisel veya finansal kayıt paylaşılmaz.',
          ),
          const _Section(
            title: 'Veri paylaşımı',
            body:
                'Verilerinizi satmaz, kiralamaz veya üçüncü taraflarla '
                'paylaşmayız. Uygulamada analitik, çökme-raporlama, reklam veya '
                'izleme SDK\'sı yoktur. Google API\'lerinden alınan bilgilerin '
                'kullanımı Google API Hizmetleri Kullanıcı Verileri '
                'Politikası\'na (Sınırlı Kullanım dahil) uyar.',
          ),
          const _Section(
            title: 'Güvenlik',
            body:
                'Yerel veri uygulamanın özel depolama alanında tutulur. '
                'Yetkisiz erişimi önlemek için biyometrik / PIN kilidi '
                'desteklenir ve uygulama arka plana alındığında içerik '
                'bulanıklaştırılır. Tüm ağ iletişimi HTTPS kullanır.',
          ),
          const _Section(
            title: 'Veri saklama ve silme',
            body:
                'Verileriniz üzerinde tam kontrol sizdedir. Tüm yerel veriyi '
                'Ayarlar → Gizlilik & Veri → "Tüm veriyi sil" ile silebilirsiniz. '
                'Drive yedeğini Ayarlar → Yedekleme bölümünden silebilir veya '
                'hesabınızın bağlantısını kesebilirsiniz.',
          ),
          const SizedBox(height: 12),
          Text(
            'İletişim: $contactEmail',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Son güncelleme: 30 Haziran 2026',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// İlk açılışta bir kez gösterilen gizlilik bilgilendirme/onam diyaloğu.
/// Kapatılamaz; kullanıcı "Anladım" diyerek devam eder. "Gizlilik Politikası"
/// tam metni açar. Çağıran, gösterildikten sonra kalıcı bayrağı yazar.
Future<void> showPrivacyConsentDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: const Text('Gizliliğiniz'),
        content: Text(
          'CuNehat verilerinizi yalnızca cihazınızda saklar; sunucumuz yoktur. '
          'İsteğe bağlı Google Drive yedeği yalnızca siz açarsanız, kendi '
          'Drive\'ınızdaki özel bir klasöre yazılır. Verileriniz üçüncü '
          'taraflarla paylaşılmaz; reklam veya izleme yoktur.',
          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push(AppRoutes.privacyPolicy);
            },
            child: const Text('Gizlilik Politikası'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anladım'),
          ),
        ],
      );
    },
  );
}
