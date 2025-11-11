import 'package:flutter/material.dart';

class IncomeView extends StatelessWidget {
  const IncomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: const Text("INCOME",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
    );
  }
}
