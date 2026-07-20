import 'dart:io';

import 'package:flutter/material.dart';

import 'package:cunehat/core/extensions/context_extensions.dart';

/// Fiş/fotoğraf görselini tam ekran, yakınlaştırılabilir gösteren sayfa.
/// Harici paket kullanmaz — yerleşik [InteractiveViewer] + [Image.file].
class ReceiptViewerPage extends StatelessWidget {
  final File imageFile;

  const ReceiptViewerPage({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(context.l10n.fisGoruntule),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Image.file(
            imageFile,
            fit: BoxFit.contain,
            errorBuilder: (context, _, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.broken_image_rounded,
                    color: Colors.white54, size: 48),
                const SizedBox(height: 12),
                Text(
                  context.l10n.fisCihazdaYok,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
