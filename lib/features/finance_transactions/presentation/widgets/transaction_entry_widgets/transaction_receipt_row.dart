import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/receipt_ocr_service.dart';
import 'package:cunehat/core/services/receipt_storage_service.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/receipt_viewer_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_controller.dart';

/// İşlem formunda fiş/fotoğraf eki satırı.
///
/// - Görsel yoksa: "Fiş/fotoğraf ekle" → kamera/galeri seçimi.
/// - Görsel seçilince: cihaz-içi OCR ile tutar/tarih/satıcı BOŞ alanları
///   ön-doldurur (kullanıcı kontrol edip kaydeder — otomatik kayıt yok).
/// - Görsel varsa: küçük önizleme + kaldır + dokun→tam ekran.
///
/// Diske yazma yalnız kayıt anında olur; burada [ValueNotifier]'da temp
/// [XFile] tutulur (iptalde orphan kalmaz).
class ReceiptRow extends StatelessWidget {
  final TransactionFormController controller;
  final Color accent;

  const ReceiptRow({
    super.key,
    required this.controller,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<XFile?>(
      valueListenable: controller.pickedReceipt,
      builder: (context, picked, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: controller.receiptFileName,
          builder: (context, savedName, _) {
            final hasImage = picked != null || savedName != null;
            if (!hasImage) return _AddButton(accent: accent, onPick: () => _pick(context));
            return _Preview(
              controller: controller,
              accent: accent,
              picked: picked,
              savedName: savedName,
              onReplace: () => _pick(context),
              onRemove: () {
                controller.pickedReceipt.value = null;
                controller.receiptFileName.value = null;
                controller.ocrApplied.value = false;
              },
            );
          },
        );
      },
    );
  }

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(ctx.l10n.fisKamera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(ctx.l10n.fisGaleri),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final XFile? file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 70,
    );
    if (file == null) return;

    controller.pickedReceipt.value = file;
    await _runOcr(file.path);
  }

  /// Görseli OCR'lar ve yalnızca BOŞ/varsayılan alanları doldurur.
  Future<void> _runOcr(String path) async {
    controller.ocrRunning.value = true;
    controller.ocrApplied.value = false;
    try {
      final result = await getIt<ReceiptOcrService>().scan(path);
      var applied = false;

      if (result.amount != null &&
          controller.amountController.text.trim().isEmpty) {
        controller.amountController.text = formatAmountForInput(result.amount!);
        applied = true;
      }
      if (result.merchant != null &&
          controller.titleController.text.trim().isEmpty) {
        controller.titleController.text = result.merchant!;
        applied = true;
      }
      if (result.date != null && _isDefaultToday(controller.dateTime.value)) {
        // Saat kullanıcının seçtiği (varsayılan şimdi) gibi kalsın, gün OCR'dan.
        final now = controller.dateTime.value;
        controller.dateTime.value = DateTime(result.date!.year,
            result.date!.month, result.date!.day, now.hour, now.minute);
        applied = true;
      }
      controller.ocrApplied.value = applied;
    } catch (e) {
      debugPrint('Fiş OCR hatası: $e'); // Ek yine de eklenir; OCR başarısızlığı akışı bozmaz.
    } finally {
      controller.ocrRunning.value = false;
    }
  }

  bool _isDefaultToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

// ============================================================ Empty state

class _AddButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onPick;

  const _AddButton({required this.accent, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.onSurface.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.fisEkle,
                  style: TextStyle(
                      color: cs.onSurface, fontWeight: FontWeight.w500),
                ),
              ),
              Icon(Icons.add_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================ Preview

class _Preview extends StatelessWidget {
  final TransactionFormController controller;
  final Color accent;
  final XFile? picked;
  final String? savedName;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  const _Preview({
    required this.controller,
    required this.accent,
    required this.picked,
    required this.savedName,
    required this.onReplace,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _Thumb(picked: picked, savedName: savedName),
              const SizedBox(width: 12),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: controller.ocrRunning,
                  builder: (context, running, _) {
                    if (running) {
                      return Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(context.l10n.fisOcrTaraniyor,
                                style: TextStyle(
                                    fontSize: 13, color: cs.onSurfaceVariant)),
                          ),
                        ],
                      );
                    }
                    return Text(
                      context.l10n.fisEkli,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface),
                    );
                  },
                ),
              ),
              IconButton(
                tooltip: context.l10n.fisDegistir,
                icon: Icon(Icons.autorenew_rounded,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.9)),
                onPressed: onReplace,
              ),
              IconButton(
                tooltip: context.l10n.fisKaldir,
                icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: controller.ocrApplied,
          builder: (context, applied, _) {
            if (!applied) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 14, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.l10n.fisOcrDolduruldu,
                      style: TextStyle(fontSize: 12, color: accent),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================ Thumbnail

class _Thumb extends StatelessWidget {
  final XFile? picked;
  final String? savedName;

  const _Thumb({required this.picked, required this.savedName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 52,
          height: 52,
          child: _image(context),
        ),
      ),
    );
  }

  Widget _image(BuildContext context) {
    final p = picked;
    if (p != null) return Image.file(File(p.path), fit: BoxFit.cover);
    return FutureBuilder<File>(
      future: getIt<ReceiptStorageService>().fileFor(savedName!),
      builder: (context, snap) {
        final file = snap.data;
        if (file == null) return const ColoredBox(color: Colors.black12);
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Colors.black12,
            child: Icon(Icons.broken_image_rounded, size: 20),
          ),
        );
      },
    );
  }

  Future<void> _open(BuildContext context) async {
    final p = picked;
    File? file;
    if (p != null) {
      file = File(p.path);
    } else if (savedName != null) {
      file = await getIt<ReceiptStorageService>().fileFor(savedName!);
    }
    if (file == null || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReceiptViewerPage(imageFile: file!)),
    );
  }
}
