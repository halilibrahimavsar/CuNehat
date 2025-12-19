import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_managment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NoWalletView extends StatelessWidget {
  final String infoText;
  final bool showButton;
  const NoWalletView({
    super.key,
    required this.infoText,
    this.showButton = true,
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
            Visibility(
              visible: showButton,
              child: ElevatedButton(
                onPressed: () {
                  final scaffoldState = context
                      .findAncestorStateOfType<AnimatedScaffoldWrapperState>();
                  scaffoldState?.openWalletDialog(
                    WalletSheetContent(
                      scrollController: ScrollController(),
                      userId: FirebaseAuth.instance.currentUser!.uid,
                    ),
                  );
                },
                child: const Text('Yeni Cüzdan Oluştur'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
