import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Alt navigasyon kaydırıcısının (SliderButtonView) hem yatay hem dikey
/// jestini AYNI GestureDetector taşıdığından (bkz. paket içi SliderKnob),
/// bunları ayrı Showcase adımlarıyla göstermek mümkün değil — tek adımda,
/// görsel bir diyagramla üç davranışı birden anlatır: yatay geçiş, dikey
/// alt sayfa navigasyonu, dokunarak ekleme.
class OnboardingNavigationHintCard extends StatelessWidget {
  const OnboardingNavigationHintCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingNavHintHeader,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _hintRow(
            context,
            Icons.swap_horiz_rounded,
            l10n.onboardingNavHintSwipeTitle,
            l10n.onboardingNavHintSwipeDesc,
          ),
          const SizedBox(height: 10),
          _hintRow(
            context,
            Icons.swap_vert_rounded,
            l10n.onboardingNavHintDragTitle,
            l10n.onboardingNavHintDragDesc,
          ),
          const SizedBox(height: 10),
          _hintRow(
            context,
            Icons.touch_app_rounded,
            l10n.onboardingNavHintAddTitle,
            l10n.onboardingNavHintAddDesc,
          ),
        ],
      ),
    );
  }

  Widget _hintRow(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
