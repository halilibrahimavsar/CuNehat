// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:ui';

/// ========================================
/// 🎨 ANIMATED SCAFFOLD WRAPPER
/// ========================================
/// Ana sayfayı drawer ve wallet açıldığında animasyonlu küçülten wrapper
class AnimatedScaffoldWrapper extends StatefulWidget {
  final Widget child;
  final Widget drawer;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const AnimatedScaffoldWrapper({
    super.key,
    required this.child,
    required this.drawer,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  State<AnimatedScaffoldWrapper> createState() =>
      AnimatedScaffoldWrapperState();
}

class AnimatedScaffoldWrapperState extends State<AnimatedScaffoldWrapper>
    with TickerProviderStateMixin {
  late AnimationController _drawerController;
  late AnimationController _walletController;

  late Animation<double> _drawerScaleAnimation;
  late Animation<Offset> _drawerSlideAnimation;
  late Animation<double> _drawerRotationAnimation;

  late Animation<double> _walletScaleAnimation;
  late Animation<Offset> _walletSlideAnimation;
  late Animation<double> _walletRotationAnimation;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final bool _isWalletOpen = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // ========== DRAWER ANIMATIONS ==========
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _drawerScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.75, // Daha derin (daha küçük)
    ).animate(CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOutBack, // Bounce efekti için
    ));

    _drawerSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.7, 0.0), // Sağa daha fazla kaydır
    ).animate(CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOutCubic,
    ));

    _drawerRotationAnimation = Tween<double>(
      begin: 0.0,
      end: -0.08, // Daha belirgin sola döndür
    ).animate(CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOutCubic,
    ));

    // ========== WALLET ANIMATIONS ==========
    _walletController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _walletScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.80, // Daha derin
    ).animate(CurvedAnimation(
      parent: _walletController,
      curve: Curves.easeOutBack,
    ));

    _walletSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -0.2), // Yukarı daha fazla kaydır
    ).animate(CurvedAnimation(
      parent: _walletController,
      curve: Curves.easeOutCubic,
    ));

    _walletRotationAnimation = Tween<double>(
      begin: 0.0,
      end: -0.04, // Daha belirgin geriye döndür
    ).animate(CurvedAnimation(
      parent: _walletController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _drawerController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  /// Wallet dialog'unu aç (animasyonlu)
  void openWalletDialog(Widget walletContent) {
    // setState(() => _isWalletOpen = true);
    _walletController.forward();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6, // Start at 70% of screen
          minChildSize: 0.3, // Can be dragged down to 50%
          maxChildSize: 0.95, // Can be dragged up to 95%
          builder: (context, scrollController) => walletContent,
        );
      },
    ).whenComplete(() {
      _walletController.reverse();
      // setState(() => _isWalletOpen = false);
    });
  }

  /// Drawer'ı aç (animasyonlu)
  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: widget.drawer,
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _drawerController.forward();
        } else {
          _drawerController.reverse();
        }
      },
      body: Stack(
        children: [
          // ========== BACKGROUND (Drawer açıkken görünür) ==========
          AnimatedBuilder(
            animation: _drawerController,
            builder: (context, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.black.withOpacity(
                      _drawerController.value * 0.5,
                    ),
                  ),
                  if (_drawerController.value > 0.0)
                    BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: _drawerController.value * 12.0,
                        sigmaY: _drawerController.value * 12.0,
                      ),
                      child: Container(color: Colors.transparent),
                    ),
                ],
              );
            },
          ),

          // ========== MAIN CONTENT (Animasyonlu) ==========
          AnimatedBuilder(
            animation: Listenable.merge([_drawerController, _walletController]),
            builder: (context, child) {
              // Drawer ve Wallet animasyonlarını birleştir
              final combinedScale =
                  _drawerScaleAnimation.value * _walletScaleAnimation.value;

              final combinedSlide = Offset(
                _drawerSlideAnimation.value.dx + _walletSlideAnimation.value.dx,
                _drawerSlideAnimation.value.dy + _walletSlideAnimation.value.dy,
              );

              final combinedRotation = _drawerRotationAnimation.value +
                  _walletRotationAnimation.value;

              return Transform.translate(
                offset: Offset(
                  combinedSlide.dx * MediaQuery.of(context).size.width,
                  combinedSlide.dy * MediaQuery.of(context).size.height,
                ),
                child: Transform.scale(
                  scale: combinedScale,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspektif
                      ..rotateY(combinedRotation)
                      ..rotateZ(combinedRotation * 0.1), // Hafif Z rotasyonu
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        _drawerController.value * 30 +
                            _walletController.value * 20,
                      ),
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: Scaffold(
              appBar: widget.appBar,
              body: widget.child,
              floatingActionButton: widget.floatingActionButton,
            ),
          ),

          // ========== GESTURE DETECTOR (Drawer açıkken tıklanabilir overlay) ==========
          if (_drawerController.value > 0.1 || _isWalletOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                    Navigator.of(context).pop(); // Drawer'ı kapat
                  }
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
