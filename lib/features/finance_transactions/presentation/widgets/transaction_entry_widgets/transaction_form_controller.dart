import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// İşlem formunun durum yöneticisi.
///
/// Performans için tek bir [ChangeNotifier] yerine alanlara ayrılmış
/// [ValueNotifier]'lar kullanılır; böylece tutar yazılırken kategori ızgarası,
/// kategori seçilirken tarih satırı yeniden çizilmez. Metin alanları kendi
/// [TextEditingController]'larıyla yönetilir (rebuild gerektirmez).
class TransactionFormController {
  TransactionFormController({required this.isExpense});

  final bool isExpense;
  final CategoryRepository _categoryService = getIt<CategoryRepository>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  final ValueNotifier<List<CategoryEntity>> categories =
      ValueNotifier(const []);
  final ValueNotifier<bool> categoriesLoading = ValueNotifier(true);
  final ValueNotifier<String?> categoryId = ValueNotifier(null);
  final ValueNotifier<DateTime> dateTime = ValueNotifier(DateTime.now());
  final ValueNotifier<RecurringFrequency?> recurringFrequency =
      ValueNotifier(null);
  final ValueNotifier<bool> submitting = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);

  /// Kaydedilmemiş, yeni seçilen fiş görseli (image_picker'ın temp dosyası).
  /// Diske ancak kayıt anında ([ReceiptStorageService.persist]) kopyalanır;
  /// önizleme + OCR bu temp dosyadan yapılır (iptalde orphan kalmasın).
  final ValueNotifier<XFile?> pickedReceipt = ValueNotifier(null);

  /// Düzenlemede zaten kayıtlı fişin dosya adı; kullanıcı kaldırırsa null olur.
  final ValueNotifier<String?> receiptFileName = ValueNotifier(null);

  /// OCR taraması sürerken true (küçük yükleniyor göstergesi için).
  final ValueNotifier<bool> ocrRunning = ValueNotifier(false);

  /// OCR alanları doldurunca kısa "kontrol et" ipucunu tetikler.
  final ValueNotifier<bool> ocrApplied = ValueNotifier(false);

  bool _disposed = false;

  void initialize(TransactionEntity t) {
    titleController.text = t.title;
    amountController.text = formatAmountForInput(t.amount);
    categoryId.value = t.tag;
    dateTime.value = t.date;
    receiptFileName.value = t.receiptFileName;
  }

  Future<void> loadCategories() async {
    categoriesLoading.value = true;
    try {
      final list = await _categoryService.getCategories(isExpense);
      if (_disposed) return;
      categories.value = list;

      // Kategori seçimi ZORUNLUDUR: hiçbir zaman otomatik doldurulmaz.
      // Eskiden listenin ilkine ("Yemek") düşülüyordu; kullanıcı seçim
      // yaptığını sanıp yanlış kategoriye kaydediyordu. Yalnız artık var
      // olmayan bir seçim (silinmiş kategori) temizlenir.
      final current = categoryId.value;
      if (current != null && !list.any((c) => c.id == current)) {
        categoryId.value = null;
      }
    } catch (e) {
      debugPrint('Kategori yükleme hatası: $e');
    } finally {
      if (!_disposed) categoriesLoading.value = false;
    }
  }

  double? get parsedAmount => parseMoneyInput(amountController.text);

  /// Geçerliyse `null`, değilse hata mesajını döndürür.
  ///
  /// Kategori mesajı dışarıdan verilir (l10n çağıran tarafta kalır —
  /// bkz. [validateAmount]'ın `maxExceededMessage` parametresi).
  String? validate({required String categoryRequiredMessage}) {
    // Not (title) zorunluluğu kaldırıldı
    final amountError = validateAmountInput(amountController.text);
    if (amountError != null) return amountError;
    if (categoryId.value == null) return categoryRequiredMessage;
    return null;
  }

  void dispose() {
    _disposed = true;
    titleController.dispose();
    amountController.dispose();
    categories.dispose();
    categoriesLoading.dispose();
    categoryId.dispose();
    dateTime.dispose();
    recurringFrequency.dispose();
    submitting.dispose();
    error.dispose();
    pickedReceipt.dispose();
    receiptFileName.dispose();
    ocrRunning.dispose();
    ocrApplied.dispose();
  }
}
