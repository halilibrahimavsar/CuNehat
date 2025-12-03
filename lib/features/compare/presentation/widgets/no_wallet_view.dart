import 'package:flutter/material.dart';

class NoWalletView extends StatelessWidget {
  const NoWalletView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wallet, size: 48, color: Colors.grey),
        const SizedBox(height: 16),
        Text('Aktif cüzdan bulunamadı'),
      ],
    );
  }
}
