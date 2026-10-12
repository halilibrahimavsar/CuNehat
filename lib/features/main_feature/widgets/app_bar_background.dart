import 'package:cunehat/core/config/feature_flags.dart';
import 'package:cunehat/features/credit_card/presentation/mini_credit_card.dart';
import 'package:cunehat/features/main_feature/utils/app_bar_style_helper.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Üst çubuğun kaydırıcıya bağlı gradyan zemini.
///
/// Kare başına yalnız BU ağaç yeniden kurulur; başlık tarafı ayrık duruma
/// bağlıdır (bkz. `SliderStateBuilder`).
///
/// **Kart bağlamı.** Etkin bağlam hesaba bağlı bir KARTSA zemin o kartın
/// rengine bürünür (yalnız İşlemler durumunda; Birikim/Borç hesabın
/// verisidir). "Şu an karttayım" bilgisi böylece ekranın en büyük yüzeyinde
/// durur — eskiden yalnız küçük bir hapın kenarlığındaydı ve kaçıyordu
/// (kullanıcı şikâyeti, 12 Eki 2026).
///
/// **TUZAK — burada çocuksuz `DecoratedBox` KULLANILAMAZ.** `AppBar`,
/// `flexibleSpace`i `Stack(fit: StackFit.passthrough)` içine koyuyor
/// (`app_bar.dart:1198`), yani kısıtlar GEVŞEK geçiyor; çocuksuz bir
/// `RenderProxyBox` gevşek kısıtta `constraints.smallest`e, yani sıfır
/// yüksekliğe çöker. Ölçüldü: `DecoratedBox` → `Size(800, 0)`,
/// `Container` → `Size(800, 70)`. `Container` çocuksuz olduğunda kendini
/// `BoxConstraints.expand()` ile büyütmeyi zaten yapıyor; gradyan bir kez
/// bu yüzden görünmez oldu.
class AppBarBackground extends StatefulWidget {
  const AppBarBackground({super.key, required this.sliderAnimation});

  final Animation<double> sliderAnimation;

  @override
  State<AppBarBackground> createState() => _AppBarBackgroundState();
}

class _AppBarBackgroundState extends State<AppBarBackground> {
  /// Son görülen kartın renkleri. Karttan hesaba dönülürken renk SOLARKEN de
  /// bilinmek zorunda: o sırada etkin kart artık yoktur.
  List<Color>? _cardColors;

  /// Etkin bağlam hesaba bağlı bir kartsa o kart.
  WalletEntity? _activeCard(BuildContext context) {
    if (!FeatureFlags.creditCards) return null;
    final WalletState state;
    try {
      state = context.watch<WalletBloc>().state;
    } on ProviderNotFoundException {
      // WalletBloc'suz ağaç (yalıtılmış testler): düz zemin.
      return null;
    }
    if (state is! WalletLoadedSt) return null;
    final active = state.activeWallet;
    if (active == null || !active.isCreditCard) return null;
    final owner = accountOf(active, state.wallets);
    return active.id == owner.id ? null : active;
  }

  @override
  Widget build(BuildContext context) {
    final card = _activeCard(context);
    if (card != null) _cardColors = creditCardGradient(card).colors;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: card == null ? 0.0 : 1.0),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, cardFactor, _) => AnimatedBuilder(
        animation: widget.sliderAnimation,
        // `AnimatedContainer` DEĞİL: her karede yeni bir hedef aldığı için
        // gradyan parmağı takip etmek yerine 300 ms geriden geliyordu.
        builder: (context, _) => Container(
          key: const ValueKey('app-bar-background'),
          decoration: AppBarStyleHelper.getAppbarDecoration(
            widget.sliderAnimation.value,
            cardColors: _cardColors,
            cardFactor: cardFactor,
          ),
        ),
      ),
    );
  }
}
