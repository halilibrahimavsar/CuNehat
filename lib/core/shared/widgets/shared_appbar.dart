// ============================================
// MODERN SHARED APPBAR WITH ANIMATIONS
// ============================================

import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_managment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ModernSharedAppbar extends StatefulWidget implements PreferredSizeWidget {
  final double currentSliderValue;

  const ModernSharedAppbar({
    super.key,
    required this.currentSliderValue,
  });

  @override
  State<ModernSharedAppbar> createState() => _ModernSharedAppbarState();

  @override
  Size get preferredSize => const Size(double.maxFinite, 70);
}

class _ModernSharedAppbarState extends State<ModernSharedAppbar>
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
      return Color.lerp(Colors.red[700]!, Colors.blue[700]!, value * 2)!;
    } else {
      return Color.lerp(
          Colors.blue[700]!, Colors.green[700]!, (value - 0.5) * 2)!;
    }
  }

  List<Color> _getAppBarGradient(double value) {
    if (value < 0.5) {
      return [
        Color.lerp(Colors.red[400]!, Colors.blue[400]!, value * 2)!,
        Color.lerp(Colors.red[700]!, Colors.blue[700]!, value * 2)!,
        Color.lerp(Colors.red[900]!, Colors.blue[900]!, value * 2)!,
      ];
    } else {
      return [
        Color.lerp(Colors.blue[400]!, Colors.green[400]!, (value - 0.5) * 2)!,
        Color.lerp(Colors.blue[700]!, Colors.green[700]!, (value - 0.5) * 2)!,
        Color.lerp(Colors.blue[900]!, Colors.green[900]!, (value - 0.5) * 2)!,
      ];
    }
  }

  String _getCurrentModeText(double value) {
    if (value < 0.25) return "Gider Modu";
    if (value > 0.75) return "Gelir Modu";
    return "Karşılaştırma";
  }

  IconData _getCurrentModeIcon(double value) {
    if (value < 0.25) return Icons.trending_down_rounded;
    if (value > 0.75) return Icons.trending_up_rounded;
    return Icons.compare_arrows_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = widget.currentSliderValue;

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 8,
      shadowColor: _getAppBarColor(currentValue).withOpacity(0.3),
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
              color: _getAppBarColor(currentValue).withOpacity(0.4),
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

  Widget _buildAppBarContent(
      BuildContext context, WalletState state, double currentValue) {
    switch (state) {
      case WalletLoadedSt():
        return Row(
          children: [
            // Menu Button with Animation
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: IconButton(
                  onPressed: () {
                    final scaffoldState = context.findAncestorStateOfType<
                        AnimatedScaffoldWrapperState>();
                    scaffoldState?.openDrawer();
                  },
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Wallet Info with Shimmer Effect
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Balance
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: state.activeWallet?.balance.toDouble() ?? 0,
                    ),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Text(
                        value.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      );
                    },
                  ),

                  // Wallet Name & Mode
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          state.activeWallet?.name ?? "Aktif cüzdan bulunamadı",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCurrentModeIcon(currentValue),
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getCurrentModeText(currentValue),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Wallet Button with Pulse Animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        final scaffoldState = context.findAncestorStateOfType<
                            AnimatedScaffoldWrapperState>();
                        scaffoldState?.openWalletDialog(
                          WalletSheetContent(
                            scrollController: ScrollController(),
                            userId: FirebaseAuth.instance.currentUser!.uid,
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );

      case WalletLoadingSt():
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        );

      default:
        return const Text(
          "Aktif cüzdan bulunamadı",
          style: TextStyle(color: Colors.white),
        );
    }
  }
}

// ============================================
// MODERN DRAWER WITH GLASSMORPHISM
// ============================================
