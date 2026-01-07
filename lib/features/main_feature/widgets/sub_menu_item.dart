import 'package:flutter/material.dart';

class SubMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  SubMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
