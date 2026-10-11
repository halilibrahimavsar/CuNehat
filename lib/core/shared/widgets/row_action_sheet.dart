import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/pressable_scale.dart';
import 'package:flutter/material.dart';

/// Bir satırın eylem sayfasındaki tek seçenek.
class RowAction<T> {
  final T value;
  final IconData icon;
  final String title;
  final String? subtitle;

  /// İkon rengi; verilmezse nötr. [destructive] eylemde yok sayılır.
  final Color? color;

  /// Sil / kapat / kaldır: ikon ve başlık kırmızı yazılır. Yıkıcı eylem
  /// listenin SONUNDA durur (sırayı çağıran verir).
  final bool destructive;

  /// Kapalıysa satır soluk çizilir ve dokunulamaz. Neden kapalı olduğu
  /// [subtitle]'da yazmalı: düğmeyi sessizce gizlemek kullanıcıyı "silme
  /// nerede?" diye aratır.
  final bool enabled;

  const RowAction({
    required this.value,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
    this.destructive = false,
    this.enabled = true,
  });
}

/// Uygulamanın TEK satır-eylem yüzeyi: tutamak, kaydın adı, altında eylemler.
///
/// Eskiden aynı iş dört ayrı dille yapılıyordu: işlem ve birikim satırı alt
/// sayfa açıyor, borç kartı dokununca açılır menü gösteriyor, hedef ve
/// bekleyen düzenli işlem ⋮'den açılır menü açıyor, bütçe ve şablon çıplak
/// bir çöp kutusu taşıyordu. Kullanıcı her modülde "bu satırla ne
/// yapabilirim?" sorusunun yanıtını baştan arıyordu.
///
/// Seçilen eylemin değeriyle kapanır; iş mantığı çağıranda kalır.
class RowActionSheet<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;

  /// Eylemlerin üstünde duran bilgi notu (ör. kilitli kaydın neden
  /// düzenlenemediği).
  final Widget? notice;
  final List<RowAction<T>> actions;

  /// Satır anahtarlarının öneki: her satır `<önek>-<eylem adı>` anahtarını
  /// taşır.
  final String keyPrefix;

  const RowActionSheet({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.actions,
    this.subtitle,
    this.notice,
    this.keyPrefix = 'row-action',
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color accent,
    required List<RowAction<T>> actions,
    String? subtitle,
    Widget? notice,
    String keyPrefix = 'row-action',
  }) {
    return showRowActionSheet<T>(
      context,
      builder: (_) => RowActionSheet<T>(
        title: title,
        subtitle: subtitle,
        icon: icon,
        accent: accent,
        notice: notice,
        actions: actions,
        keyPrefix: keyPrefix,
      ),
    );
  }

  static String _nameOf(Object? value) =>
      value is Enum ? value.name : value.toString();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Material (Container değil): içerideki ListTile zeminini ve ink dalgasını
    // en yakın Material'a boyar. Renkli bir DecoratedBox araya girerse dalga
    // görünmez olur ve Flutter debug'da assertion atar.
    return Material(
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (notice != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: notice,
                ),
              for (final action in actions) _tile(context, action),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, RowAction<T> action) {
    final cs = Theme.of(context).colorScheme;
    final tint = action.destructive ? cs.error : null;
    return ListTile(
      key: ValueKey('$keyPrefix-${_nameOf(action.value)}'),
      enabled: action.enabled,
      leading: Icon(
        action.icon,
        color: action.enabled ? (tint ?? action.color) : null,
      ),
      title: Text(
        action.title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: action.enabled ? (tint ?? cs.onSurface) : null,
        ),
      ),
      subtitle: action.subtitle == null
          ? null
          : Text(
              action.subtitle!,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
      onTap: () => Navigator.pop<T>(context, action.value),
    );
  }
}

/// [RowActionSheet] çerçevesiyle (saydam zemin, içeriğe göre yükseklik) bir
/// alt sayfa açar. Kendi sarmalayıcı widget'ı olan sayfalar
/// (`TransactionActionSheet` gibi) bunu doğrudan çağırır.
Future<T?> showRowActionSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    // Yükseklik içeriğe göre: varsayılan sınır ekranın 9/16'sı ve dört
    // eylem + başlık 600dp'lik ekranda 29px taşıyordu (ölçüldü). İçerik
    // ayrıca kaydırılabilir — büyük yazı ölçeğinde de taşmaz.
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

/// En sık rastlanan menü: Düzenle · Sil.
enum RowEditDelete { edit, delete }

/// [RowEditDelete] menüsünün satırları. Metinler verilmezse genel
/// "Düzenle" / "Sil" kullanılır.
List<RowAction<RowEditDelete>> editDeleteActions(
  BuildContext context, {
  String? editTitle,
  String? deleteTitle,
  String? deleteSubtitle,
}) {
  final l10n = context.l10n;
  return [
    RowAction(
      value: RowEditDelete.edit,
      icon: Icons.edit_rounded,
      color: Colors.blueGrey,
      title: editTitle ?? l10n.duzenle,
    ),
    RowAction(
      value: RowEditDelete.delete,
      icon: Icons.delete_outline_rounded,
      title: deleteTitle ?? l10n.sil,
      subtitle: deleteSubtitle,
      destructive: true,
    ),
  ];
}

/// Dokununca kendi eylem sayfasını açan kart sarmalayıcısı: ayrı bir detay
/// sayfası olmayan kayıtlar (borç, alacak) için. Kartın tamamı hedeftir.
class RowActionTarget<T> extends StatelessWidget {
  final Widget child;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final List<RowAction<T>> actions;
  final ValueChanged<T> onSelected;

  const RowActionTarget({
    super.key,
    required this.child,
    required this.title,
    required this.icon,
    required this.accent,
    required this.actions,
    required this.onSelected,
    this.subtitle,
  });

  Future<void> _open(BuildContext context) async {
    final value = await RowActionSheet.show<T>(
      context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      accent: accent,
      actions: actions,
    );
    if (value == null || !context.mounted) return;
    onSelected(value);
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(onTap: () => _open(context), child: child);
  }
}

/// Satırın ⋮ düğmesi: her modülde aynı ikon, aynı ipucu, aynı dokunma alanı.
class RowMenuButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double iconSize;

  const RowMenuButton({super.key, required this.onPressed, this.iconSize = 22});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.secenekler,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
      icon: Icon(
        Icons.more_vert_rounded,
        size: iconSize,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
