import 'package:flutter/material.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String title;

  const ConfirmDeleteDialog({super.key, required this.title});

  /// Kullanımı kolaylaştıran statik metod
  static Future<bool?> show(
    BuildContext context, {
    required String title,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // dışarı tıklayınca kapanmasın
      builder: (ctx) => ConfirmDeleteDialog(title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.orange,
        size: 48,
      ),
      title: const Text(
        'Silme Onayı',
        textAlign: TextAlign.center,
      ),
      content: Text(
        '"$title" adlı geliri silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('İptal'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          icon: const Icon(Icons.delete_forever, size: 18),
          label: const Text('Sil'),
        ),
      ],
    );
  }
}
