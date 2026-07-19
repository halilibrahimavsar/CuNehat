import 'package:flutter/widgets.dart';

import '../../config/di/injection.dart';
import 'onboarding_coordinator.dart';
import 'onboarding_flow.dart';

/// `StatelessWidget` alt sayfalar için (kendi initState'leri olmadığından)
/// "bu sayfaya ilk kez gelindiğinde turu otomatik başlat" mantığını taşıyan
/// ince sarmalayıcı. Görsel bir etkisi yoktur — [child]'ı olduğu gibi
/// render eder; iş mantığı [InvestmentMoneyPage] vb. sayfalardaki
/// `_maybeShowTour` deseniyle aynıdır.
class OnboardingAutoTourTrigger extends StatefulWidget {
  final OnboardingFlow flow;
  final List<GlobalKey> Function() keysBuilder;
  final Widget child;

  const OnboardingAutoTourTrigger({
    super.key,
    required this.flow,
    required this.keysBuilder,
    required this.child,
  });

  @override
  State<OnboardingAutoTourTrigger> createState() =>
      _OnboardingAutoTourTriggerState();
}

class _OnboardingAutoTourTriggerState extends State<OnboardingAutoTourTrigger> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTour());
  }

  Future<void> _maybeShowTour() async {
    if (!mounted) return;
    final coordinator = getIt<OnboardingCoordinator>();
    final keys = widget.keysBuilder();
    coordinator.registerKeys(widget.flow, keys);
    if (coordinator.isSeen(widget.flow)) return;
    await coordinator.waitUntilStable();
    if (!mounted) return;
    await coordinator.requestStartShowCase(keys);
    await coordinator.markSeen(widget.flow);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
