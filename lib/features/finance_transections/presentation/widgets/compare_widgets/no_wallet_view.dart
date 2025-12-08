import 'package:cunehat/features/wallet/presentation/page/wallet_managment.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  isDismissible: true,
                  backgroundColor: Colors.transparent,
                  builder: (bottomSheetContext) {
                    // ✅ CRITICAL: Don't wrap in provider, it already exists in parent
                    return DraggableScrollableSheet(
                      initialChildSize: 0.7, // Start at 70% of screen
                      minChildSize: 0.5, // Can be dragged down to 50%
                      maxChildSize: 0.95, // Can be dragged up to 95%
                      builder: (context, scrollController) {
                        return WalletManagementPage(
                          userId: FirebaseAuth.instance.currentUser!.uid,
                        );
                      },
                    );
                  },
                );
              },
              child: const Text('Yeni Cüzdan Oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}
