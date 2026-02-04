import 'package:cunehat/features/main_feature/utils/app_bar_style_helper.dart';
import 'package:cunehat/features/main_feature/utils/app_constants.dart';
import 'package:cunehat/features/main_feature/widgets/app_bar_content.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ModernAppbar extends StatefulWidget implements PreferredSizeWidget {
  final double currentSliderValue;

  const ModernAppbar({
    super.key,
    required this.currentSliderValue,
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
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 8,
      shadowColor: AppBarStyleHelper.getAppBarColor(widget.currentSliderValue)
          .withValues(alpha: 0.3),
      shape: AppBarStyleHelper.getAppbarShape(widget.currentSliderValue),
      backgroundColor: AppColors.transparent,
      flexibleSpace: AnimatedContainer(
        duration: AppDurations.short,
        decoration:
            AppBarStyleHelper.getAppbarDecoration(widget.currentSliderValue),
      ),
      title: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          return AppBarContent(
            currentSliderValue: widget.currentSliderValue,
            scaleAnimation: _scaleAnimation,
            fadeAnimation: _fadeAnimation,
          );
        },
      ),
    );
  }
}
