import 'package:cunehat/features/main_feature/utils/app_bar_style_helper.dart';
import 'package:cunehat/features/main_feature/utils/app_constants.dart';
import 'package:cunehat/features/main_feature/widgets/app_bar_background.dart';
import 'package:cunehat/features/main_feature/widgets/app_bar_content.dart';
import 'package:cunehat/features/main_feature/widgets/slider_state_builder.dart';
import 'package:flutter/material.dart';

/// Ana kabuğun üst çubuğu.
///
/// AppBar'ın kaydırıcıya bağlı İKİ ayrı bağımlılığı var ve ikisinin tazelenme
/// sıklığı çok farklı:
///
/// * **Zemin gradyanı** ham değerle sürekli değişir → kare başına.
/// * **Başlık içeriği** yalnız aktif duruma bakar → tam sürüşte 2 kez.
///
/// Eskiden ikisi de tek bir `AnimatedBuilder` altındaydı: kaydırma boyunca
/// `BlocBuilder<WalletBloc>`, `AppBarContent`, `Showcase` ve kur servisine
/// bağlı `MoneyText` saniyede 60 kez yeniden kuruluyordu. Ayrıca zemin
/// `AnimatedContainer(300 ms)` idi ve her karede yeni bir hedef aldığı için
/// parmağı takip etmek yerine 300 ms geriden geliyordu.
class ModernAppbar extends StatefulWidget implements PreferredSizeWidget {
  final Animation<double> sliderAnimation;

  const ModernAppbar({
    super.key,
    required this.sliderAnimation,
  });

  @override
  State<ModernAppbar> createState() => _ModernAppbarState();

  @override
  Size get preferredSize => const Size(double.maxFinite, AppSizes.appBarHeight);
}

class _ModernAppbarState extends State<ModernAppbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _controller.forward();
  }

  void _initAnimations() {
    _controller = AnimationController(
      duration: AppDurations.long,
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `AppBar`'ın kendisi yalnız DURUM değişince kurulur (gölge rengi ve
    // başlık ona bağlı); gradyan zemin kare başına kendi içinde tazelenir.
    return SliderStateBuilder(
      animation: widget.sliderAnimation,
      builder: (context, state) => AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: AppSizes.appBarHeight,
        titleSpacing: 0,
        elevation: 8,
        shadowColor: AppBarStyleHelper.getAppBarColorForState(state)
            .withValues(alpha: 0.3),
        shape: AppBarStyleHelper.getAppbarShape(),
        backgroundColor: AppColors.transparent,
        flexibleSpace: AppBarBackground(
          sliderAnimation: widget.sliderAnimation,
        ),
        title: AppBarContent(
          currentState: state,
          scaleAnimation: _scaleAnimation,
          fadeAnimation: _fadeAnimation,
        ),
      ),
    );
  }
}
