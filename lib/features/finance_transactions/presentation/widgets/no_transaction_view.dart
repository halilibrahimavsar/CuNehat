// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class NoTransactionView extends StatelessWidget {
  const NoTransactionView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.account_balance_wallet_outlined,
          size: 64,
          color: Colors.blue[300]!.withOpacity(0.6),
        ),
        const SizedBox(height: 16),
        Text(
          "Henüz işlem bulunmuyor",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Gelir veya gider ekleyerek başlayın",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
