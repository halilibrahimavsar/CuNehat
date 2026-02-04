import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_managment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/features/amount_visibility/amount_visibility_cubit.dart';
import 'package:unified_flutter_features/features/amount_visibility/ibo_amount_display.dart';

class ModernAppbar extends StatefulWidget implements PreferredSizeWidget {
  final double currentSliderValue;

  const ModernAppbar({
    super.key,
    required this.currentSliderValue,
  });

  @override
  State<ModernAppbar> createState() => _ModernAppbarState();

  @override
  Size get preferredSize => const Size(double.maxFinite, 70);
}

class _ModernAppbarState extends State<ModernAppbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getAppBarColor(double value) {
    if (value < 0.5) {
      return Color.lerp(Colors.green[700]!, Colors.blue[700]!, value * 2)!;
    } else {
      return Color.lerp(
          Colors.blue[700]!, Colors.red[700]!, (value - 0.5) * 2)!;
    }
  }

  List<Color> _getAppBarGradient(double value) {
    if (value < 0.5) {
      return [
        Color.lerp(Colors.green[400]!, Colors.blue[400]!, value * 2)!,
        Color.lerp(Colors.green[700]!, Colors.blue[700]!, value * 2)!,
        Color.lerp(Colors.green[900]!, Colors.blue[900]!, value * 2)!,
      ];
    } else {
      return [
        Color.lerp(Colors.blue[400]!, Colors.red[400]!, (value - 0.5) * 2)!,
        Color.lerp(Colors.blue[700]!, Colors.red[700]!, (value - 0.5) * 2)!,
        Color.lerp(Colors.blue[900]!, Colors.red[900]!, (value - 0.5) * 2)!,
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = widget.currentSliderValue;

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 8,
      shadowColor: _getAppBarColor(currentValue).withValues(alpha: 0.3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      backgroundColor: Colors.transparent,
      flexibleSpace: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getAppBarGradient(currentValue),
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: _getAppBarColor(currentValue).withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      ),
      title: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildAppBarContent(context, state, currentValue),
          );
        },
      ),
    );
  }

  // lib/core/shared/widgets/shared_appbar.dart - _buildAppBarContent metodunu güncelleyin

  Widget _buildAppBarContent(
      BuildContext context, WalletState state, double currentValue) {
    // 1. Menu Button (Always visible)
    final menuButton = ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: IconButton(
          onPressed: () {
            final scaffoldState =
                context.findAncestorStateOfType<AnimatedScaffoldWrapperState>();
            scaffoldState?.openDrawer();
          },
          icon: const Icon(Icons.grid_view_rounded,
              color: Colors.white, size: 22),
        ),
      ),
    );

    // 2. Visibility Button - YENİ!
    final visibilityButton = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const AmountVisibilityButton(),
          ),
        );
      },
    );

    // final connectionBadge = BlocBuilder<ConnectionCubit, MyConnectionState>(
    //   builder: (context, connectionState) {
    //     return Container(
    //       margin: const EdgeInsets.symmetric(horizontal: 8),
    //       padding: const EdgeInsets.all(8),
    //       decoration: BoxDecoration(
    //         color: Colors.white.withOpacity(0.2),
    //         borderRadius: BorderRadius.circular(14),
    //         border: Border.all(
    //           color: Colors.white.withOpacity(0.3),
    //           width: 1.5,
    //         ),
    //       ),
    //       child: ConnectionStatusBadge(
    //         connectionState: connectionState,
    //         size: 10,
    //       ),
    //     );
    //   },
    // );

    // 3. Center Content (Depends on state)
    Widget centerContent;

    if (state is WalletLoadedSt) {
      double valueListener = 0.0;
      String valueNameListener = "";

      if (state.activeWallet != null) {
        if (currentValue < 0.3) {
          valueListener = state.activeWallet?.investment ?? 0.0;
          valueNameListener = "YATIRIM";
        } else if (currentValue > 0.7) {
          valueListener = state.activeWallet?.debt ?? 0.0;
          valueNameListener = "BORÇ";
        } else {
          valueListener = state.activeWallet?.balance ?? 0.0;
          valueNameListener = "BAKİYE";
        }
      }

      centerContent = GestureDetector(
        onTap: () {
          final scaffoldState =
              context.findAncestorStateOfType<AnimatedScaffoldWrapperState>();
          scaffoldState?.openWalletDialog(
            WalletSheetContent(
              scrollController: ScrollController(),
              userId: FirebaseAuth.instance.currentUser!.uid,
            ),
          );
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Wallet Name Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wallet,
                        size: 12, color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        valueNameListener == "BAKİYE"
                            ? (state.activeWallet?.name.toUpperCase() ??
                                "CÜZDAN")
                            : "${state.activeWallet?.name.toUpperCase() ?? 'CÜZDAN'} • $valueNameListener",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Balance - AmountDisplay ile değiştirildi
              BlocBuilder<AmountVisibilityCubit, bool>(
                builder: (context, isVisible) {
                  return AmountDisplay(
                    amount: valueListener,
                    animationCurve: Curves.decelerate,
                    obscureMode: AmountObscureMode.blur,
                    alignment: Alignment.center,
                    // animationDuration: const Duration(milliseconds: 1000),
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      shadows: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    } else if (state is WalletLoadingSt) {
      centerContent = const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      );
    } else {
      centerContent = Center(
        child: Text(
          state is NoWalletSt ? "Cüzdan Oluştur" : "Cüzdan Seçin",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          menuButton,
          Expanded(child: centerContent),
          // connectionBadge,
          visibilityButton, // Göz butonu eklendi
        ],
      ),
    );
  }
}
