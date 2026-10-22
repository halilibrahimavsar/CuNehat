import 'package:cunehat/core/constants/app_version.dart';
import 'package:cunehat/core/feedback/feedback_mail.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/features/settings/presentation/page/privacy_policy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

/// Card displaying app information and logout option, styled with AppCard.
class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  /// E-posta taslağı açar; cihazda e-posta uygulaması yoksa adresi panoya
  /// kopyalar ve bunu söyler — satır hiçbir durumda sessiz kalmaz.
  static Future<void> _sendFeedback(BuildContext context) async {
    final l10n = context.l10n;
    const to = PrivacyPolicyPage.contactEmail;
    final opened = await FeedbackMail.compose(
      to: to,
      subject: l10n.feedbackMailSubject(kAppName, kAppVersionName),
      // Sürüm, sorunu yeniden üretmek için gereken tek bilgi; kişisel veri
      // eklenmez.
      body: '\n\n—\n$kAppName $kAppVersionName',
    );
    if (opened) return;
    await Clipboard.setData(const ClipboardData(text: to));
    AppMessenger.info(l10n.feedbackNoMailApp(to));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.info_outline, color: scheme.primary),
            title: Text(
              context.l10n.version,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            // Sabitten: elle yazılmış '1.0.0' 1.1.0'da da 1.0.0 gösteriyordu.
            trailing: Text(
              kAppVersionName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Divider(height: 1, color: scheme.outline.withValues(alpha: 0.1)),
          ListTile(
            leading: Icon(Icons.code, color: scheme.primary),
            title: Text(
              context.l10n.developer,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            trailing: Text(
              context.l10n.ibo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Divider(height: 1, color: scheme.outline.withValues(alpha: 0.1)),
          ListTile(
            key: const ValueKey('about-feedback'),
            leading: Icon(Icons.mail_outline_rounded, color: scheme.primary),
            title: Text(
              context.l10n.feedbackTitle,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            subtitle: Text(context.l10n.feedbackSubtitle),
            trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            onTap: () => _sendFeedback(context),
          ),
          Divider(height: 1, color: scheme.outline.withValues(alpha: 0.1)),
          // Release'te de açık: cihazda yaşanan bir hatanın tek somut izi bu
          // günlük (bkz. ErrorLog).
          ListTile(
            leading: Icon(Icons.bug_report_outlined, color: scheme.primary),
            title: Text(
              context.l10n.errorLogTitle,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            subtitle: Text(context.l10n.errorLogSubtitle),
            trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            onTap: () => context.push(AppRoutes.errorLog),
          ),
        ],
      ),
    );
  }
}
