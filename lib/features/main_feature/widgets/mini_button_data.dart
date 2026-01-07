import 'package:flutter/material.dart';

class MiniButtonData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  MiniButtonData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
