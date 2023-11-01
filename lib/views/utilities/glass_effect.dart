import 'dart:ui';
import 'package:flutter/material.dart';

class GlassEffect extends StatelessWidget {
  final Widget child;
  const GlassEffect({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: child,
      ),
    );
  }
}
