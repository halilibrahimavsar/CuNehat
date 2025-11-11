import 'package:flutter/material.dart';

class ExpenseView extends StatelessWidget {
  const ExpenseView({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: const Text("EXPENSE",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
    );
  }
}
