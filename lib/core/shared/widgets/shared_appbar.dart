// lib/shared/widgets/shared_appbar.dart
// ✅ FIXED: Uses app-level WalletBloc without wrapping in provider

// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_managment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// **SharedAppbar**: Reactive app bar with wallet integration
///
/// ✅ FIXED: Uses shared WalletBloc from app level
class SharedAppbar extends StatefulWidget implements PreferredSizeWidget {
  final double currentSliderValue;

  const SharedAppbar({
    super.key,
    required this.currentSliderValue,
  });

  @override
  State<SharedAppbar> createState() => _SharedAppbarState();

  @override
  Size get preferredSize => const Size(double.maxFinite, 50);
}

class _SharedAppbarState extends State<SharedAppbar> {
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
      ];
    } else {
      return [
        Color.lerp(Colors.blue[400]!, Colors.green[400]!, (value - 0.5) * 2)!,
        Color.lerp(Colors.blue[700]!, Colors.green[700]!, (value - 0.5) * 2)!,
      ];
    }
  }

  Color _getContentColor(double value) {
    return Colors.white;
  }

  String _getCurrentModeText(double value) {
    if (value < 0.25) return "Gider Modu";
    if (value > 0.75) return "Gelir Modu";
    return "Karşılaştırma Modu";
  }

  IconData _getCurrentModeIcon(double value) {
    if (value < 0.25) return Icons.arrow_downward;
    if (value > 0.75) return Icons.arrow_upward;
    return Icons.compare_arrows;
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = widget.currentSliderValue;

    return AppBar(
      automaticallyImplyLeading: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      titleSpacing: 0,
      backgroundColor: _getAppBarColor(currentValue),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getAppBarGradient(currentValue),
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
      ),
      title: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          switch (state) {
            case WalletLoadedSt():
              return Row(
                children: [
                  IconButton(
                    onPressed: () {
                      final scaffoldState = context.findAncestorStateOfType<
                          AnimatedScaffoldWrapperState>();
                      scaffoldState?.openDrawer();
                    },
                    icon: Icon(Icons.menu_rounded),
                  ),
                  Row(
                    children: [
                      Text(
                        state.activeWallet?.balance.toString() ?? "0",
                        style: TextStyle(
                          fontSize: 24,
                          color: _getContentColor(currentValue),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            state.activeWallet?.name ??
                                "Aktif cüzdan Bulunamadı",
                            style: TextStyle(
                              fontSize: 16,
                              color: _getContentColor(currentValue),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                _getCurrentModeIcon(currentValue),
                                size: 12,
                                color: _getContentColor(currentValue)
                                    .withOpacity(0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getCurrentModeText(currentValue),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getContentColor(currentValue)
                                      .withOpacity(0.8),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            case WalletLoadingSt():
              return Center(
                child: SingleChildScrollView(),
              );
            default:
              return Text(
                "Aktif cüzdan Bulunamadı",
              );
          }
        },
      ),
      actions: [
        // ✅ Wallet management button with badge
        IconButton(
          onPressed: () {
            // AnimatedScaffoldWrapper'ın state'ine eriş
            final scaffoldState =
                context.findAncestorStateOfType<AnimatedScaffoldWrapperState>();
            scaffoldState?.openWalletDialog(
              WalletSheetContent(
                scrollController: ScrollController(),
                userId: FirebaseAuth.instance.currentUser!.uid,
              ),
            );
          },
          icon: const Icon(Icons.wallet),
        ),
      ],
    );
  }
}
