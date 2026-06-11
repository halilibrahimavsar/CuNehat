import 'package:flutter/material.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

class WalletInfoDialog {
  static Future<void> show(BuildContext context) {
    return IboDialog.showCustomDialog(
      context,
      title: 'Cüzdan Yönetimi',
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• Aktif cüzdanınızı değiştirmek için bir cüzdana tıklayın.'),
          SizedBox(height: 8),
          Text(
              '• Aktif olan cüzdan silinemez. Silmek için önce başka bir cüzdanı aktif yapmalısınız.'),
          SizedBox(height: 8),
          Text('• Cüzdan bakiyeleri otomatik olarak güncellenir.'),
          SizedBox(height: 8),
          Text('• Her cüzdanın kendi gelir/gider kayıtları vardır.'),
          SizedBox(height: 8),
          Text(
              '• Cüzdanlarınıza ait Borç, Alacak ve Birikim tutarlarını düzenle sayfasından manuel olarak yönetebilirsiniz.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tamam'),
        ),
      ],
    );
  }
}
