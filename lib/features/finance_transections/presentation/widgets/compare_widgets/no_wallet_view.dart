import 'package:cunehat/features/wallet/presentation/page/wallet_managment.dart';
import 'package:flutter/material.dart';

class NoWalletView extends StatelessWidget {
  const NoWalletView({
    super.key,
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
              'Aktif cüzdan bulunamadı. Aşağıdaki düğme ile ilk cüzdanınızı oluşturun.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showWalletManagement(context);
              },
              child: const Text('Yeni Cüzdan Oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}
