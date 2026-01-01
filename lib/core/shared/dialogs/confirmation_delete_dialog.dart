import 'package:flutter/material.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final String itemType;
  final VoidCallback? onDelete;

  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    this.itemType = 'öğeyi',
    this.onDelete, // opsiyonel
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String itemType = 'öğeyi',
    VoidCallback? onDelete, // buraya da ekleyelim ki dışarıdan verebilelim
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfirmDeleteDialog(
        title: title,
        itemType: itemType,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.warning_amber_rounded,
          color: Colors.orange, size: 48),
      title: const Text('Silme Onayı', textAlign: TextAlign.center),
      content: Text(
        '"$title" adlı $itemType silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('İptal'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            onDelete?.call(); // <-- varsa çalışır, yoksa hiçbir şey yapmaz
            Navigator.of(context).pop(true);
          },
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
