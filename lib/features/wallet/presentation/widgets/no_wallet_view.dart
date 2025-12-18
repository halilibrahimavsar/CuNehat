import 'package:cunehat/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NoWalletView extends StatelessWidget {
  final String infoText;
  const NoWalletView({
    super.key,
    required this.infoText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.wallet, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              infoText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.go(AppRoutes.wallet);
              },
              child: const Text('Yeni Cüzdan Oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}
