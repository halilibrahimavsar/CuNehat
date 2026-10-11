import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/recent_categories.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
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
  TransactionFormController({
    required bool isExpense,
    required this.walletId,
    this.userId,
  }) : isExpense = ValueNotifier(isExpense);

  /// Gider mi gelir mi. Form İÇİNDEN değiştirilebilir ([setExpense]):
  /// eskiden tür sayfayı açan düğmeyle donuyordu — yanlış mini düğmeye basan
  /// kullanıcı sayfayı kapatıp baştan başlıyor, düzenlemede ise türü hiç
  /// değiştiremiyordu.
  final ValueNotifier<bool> isExpense;

  /// "Son kullanılanlar"ın okunacağı defterin sahibi; verilmezse o şerit
  /// boş kalır (bkz. [recentCategories]).
  final String? userId;

  /// Kategori listesinin kapsamı: yalnız bu cüzdanda görünür kalemler
  /// listelenir (bkz. `wallet_category_scope.dart`).
  final String walletId;

  /// Kaydın YAZILACAĞI cüzdan: [walletId] ya da formdaki "ödeme yöntemi"
  /// seçicisinden aynı ailenin bir kredi kartı / sahibi (bkz.
  /// `card_family.dart`). Kategori kapsamı değişmez — bağlı kart sahibinin
  /// kümesini kullanır.
  late final ValueNotifier<String> targetWalletId = ValueNotifier(walletId);

  final WalletCategoryService _categoryService = getIt<WalletCategoryService>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  final ValueNotifier<List<CategoryEntity>> categories =
      ValueNotifier(const []);
  final ValueNotifier<bool> categoriesLoading = ValueNotifier(true);
  final ValueNotifier<String?> categoryId = ValueNotifier(null);

  /// Bu cüzdanda en son kullanılan kategoriler (bkz. [recentCategoryIds]);
  /// kategori şeridinin önündeki kısayol satırını besler.
  final ValueNotifier<List<CategoryEntity>> recentCategories =
      ValueNotifier(const []);
  final ValueNotifier<DateTime> dateTime = ValueNotifier(DateTime.now());
  final ValueNotifier<RecurringFrequency?> recurringFrequency =
      ValueNotifier(null);

  /// Taksit sayısı (yalnız kredi kartı cüzdanında sunulur); 1 = tek çekim.
  final ValueNotifier<int> installments = ValueNotifier(1);
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

  /// "Kaydet ve yeni" ile az önce yazılan kaydın özeti. Sayfa açık kaldığı
  /// için alttaki defterin kendi mesajı sayfanın ARKASINDA kalır; onay
  /// formun içinde gösterilir.
  final ValueNotifier<String?> lastSaved = ValueNotifier(null);

  bool _disposed = false;

  void initialize(TransactionEntity t) {
    titleController.text = t.title;
    amountController.text = formatAmountForInput(t.amount);
    categoryId.value = t.tag;
    dateTime.value = t.date;
    receiptFileName.value = t.receiptFileName;
  }

  /// "Yeniden ekle": var olan bir işlemin içeriğiyle YENİ kayıt başlatır.
  /// Tarih bugündür (aynı harcama yeniden yapılıyor) ve fiş taşınmaz —
  /// görsel öteki kaydın belgesidir.
  void prefill(TransactionEntity t) {
    titleController.text = t.title;
    amountController.text = formatAmountForInput(t.amount);
    categoryId.value = t.tag;
  }

  /// Türü değiştirir ve kategori listesini o türe göre yeniden yükler.
  ///
  /// Seçili kategori SIFIRLANIR: gider kategorisi gelir listesinde yoktur ve
  /// kategori zorunlu olduğundan seçim kullanıcıya bırakılır. Ödeme yöntemi
  /// ve taksit yalnız giderde anlamlıdır; gelire geçince hedef, formun
  /// açıldığı cüzdana döner.
  Future<void> setExpense(bool value) async {
    if (isExpense.value == value) return;
    isExpense.value = value;
    categoryId.value = null;
    recentCategories.value = const [];
    error.value = null;
    if (!value) {
      targetWalletId.value = walletId;
      installments.value = 1;
    }
    await loadCategories();
  }

  /// "Kaydet ve yeni" sonrası formu bir sonraki kayda hazırlar. Tür, tarih
  /// ve ödeme yöntemi KALIR (art arda girilen fişler çoğunlukla aynı gün ve
  /// aynı cüzdandandır); kategori sıfırlanır — taşınsaydı kullanıcı seçim
  /// yaptığını sanıp yanlış kategoriye kaydederdi.
  void resetForNext({required String savedSummary}) {
    titleController.clear();
    amountController.clear();
    categoryId.value = null;
    recurringFrequency.value = null;
    installments.value = 1;
    pickedReceipt.value = null;
    receiptFileName.value = null;
    ocrApplied.value = false;
    error.value = null;
    submitting.value = false;
    lastSaved.value = savedSummary;
  }

  Future<void> loadCategories() async {
    categoriesLoading.value = true;
    try {
      // Düzenlenen işlemin mevcut kategorisi, bu cüzdanda gizlenmiş olsa bile
      // listede kalır — yoksa aşağıdaki "artık yok" temizliği onu düşürür ve
      // kullanıcı sadece tutarı değiştirmek isterken kategorisini kaybeder.
      final expense = isExpense.value;
      final list = await _categoryService.categoriesFor(
        walletId: walletId,
        isExpense: expense,
        alwaysInclude: categoryId.value,
      );
      // Yükleme sürerken tür değiştiyse bu yanıt bayattır.
      if (_disposed || expense != isExpense.value) return;
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
    await _loadRecentCategories();
  }

  /// Şerit bir kolaylıktır: defter okunamazsa boş kalır, form çalışmaya
  /// devam eder.
  Future<void> _loadRecentCategories() async {
    final user = userId;
    if (user == null || !getIt.isRegistered<TransactionsRepository>()) return;
    final expense = isExpense.value;
    final result = await getIt<TransactionsRepository>()
        .getTransactions(userId: user, walletId: walletId);
    if (_disposed || expense != isExpense.value) return;
    final byId = {for (final c in categories.value) c.id: c};
    recentCategories.value = result.fold(
      (_) => const [],
      (transactions) => [
        for (final id in recentCategoryIds(
          transactions,
          isExpense: expense,
          validIds: byId.keys.toSet(),
        ))
          byId[id]!,
      ],
    );
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
    recentCategories.dispose();
    isExpense.dispose();
    lastSaved.dispose();
    dateTime.dispose();
    recurringFrequency.dispose();
    installments.dispose();
    targetWalletId.dispose();
    submitting.dispose();
    error.dispose();
    pickedReceipt.dispose();
    receiptFileName.dispose();
    ocrRunning.dispose();
    ocrApplied.dispose();
  }
}
