// lib/shared/widgets/shared_appbar.dart
// ✅ FIXED: Uses app-level WalletBloc without wrapping in provider

// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_managment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      title: _buildTitle(context, currentValue),
      actions: [
        // ✅ Wallet management button with badge
        IconButton(
          onPressed: () {
            // AnimatedScaffoldWrapper'ın state'ine eriş
            final scaffoldState =
                context.findAncestorStateOfType<AnimatedScaffoldWrapperState>();
            scaffoldState?.openWalletDialog(
              WalletManagementPage(
                userId: FirebaseAuth.instance.currentUser!.uid,
              ),
            );
          },
          icon: const Icon(Icons.wallet),
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context, double currentValue) {
    return Row(
      children: [
        // User Avatar (opens drawer)
        GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getContentColor(currentValue).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              backgroundImage: NetworkImage(
                FirebaseAuth.instance.currentUser?.providerData[0].photoURL ??
                    "assets/images/logo.jpg",
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // ✅ Use shared WalletBloc for wallet info
        Expanded(
          child: Builder(
            builder: (context) {
              Widget userInfo = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FirebaseAuth.instance.currentUser?.displayName ??
                        "Anonymous",
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
                        color: _getContentColor(currentValue).withOpacity(0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getCurrentModeText(currentValue),
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              _getContentColor(currentValue).withOpacity(0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              );

              // ✅ Show active wallet info if loaded
              if (true) {
                userInfo = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User name
                    Text(
                      FirebaseAuth.instance.currentUser?.displayName ??
                          "Anonymous",
                      style: TextStyle(
                        fontSize: 14,
                        color: _getContentColor(currentValue),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Active wallet name
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 10,
                          color:
                              _getContentColor(currentValue).withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            "activeWallet.name",
                            style: TextStyle(
                              fontSize: 10,
                              color: _getContentColor(currentValue)
                                  .withOpacity(0.8),
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return userInfo;
            },
          ),
        ),
      ],
    );
  }
}
