import 'package:flutter/material.dart';

class DismissableWidget<T> extends StatelessWidget {
  final T item;
  final String dismissKey;
  final Future<bool> Function(T) onDelete;
  final Function(T) onEdit;
  final Widget child;

  const DismissableWidget(
      {super.key,
      required this.item,
      required this.dismissKey,
      required this.child,
      required this.onDelete,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(dismissKey),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Sağa kaydırma (Silme)
          return await onDelete(item);
        } else {
          // Sola kaydırma (Düzenleme)
          onEdit(item);
          return false;
        }
      },
      background: _buildDismissBackground(
        alignment: Alignment.centerLeft,
        color: Colors.blue,
        icon: Icons.edit,
        text: 'Düzenle',
      ),
      secondaryBackground: _buildDismissBackground(
        alignment: Alignment.centerRight,
        color: Colors.red,
        icon: Icons.delete,
        text: 'Sil',
      ),
      child: child,
    );
  }

  Widget _buildDismissBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ] else ...[
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white),
          ],
        ],
      ),
    );
  }
}
