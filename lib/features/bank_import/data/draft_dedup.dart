/// Taslakları olası tekrarlara göre işaretler.
///
/// Temel anahtar: (gün, işaretli-kuruş, normalize-açıklama). Banka referansı
/// (Dekont/İşlem No) varsa bu anahtara EKLENİR — yerine geçmez.
///
/// **Referans neden tek başına anahtar DEĞİL:** gerçek bir Garanti BBVA
/// ekstresinde dekont numarası işlem başına değil OPERASYON başına veriliyor;
/// bir havalenin masraf satırı ("KESİNTİ VE EKLERİ") ana havaleyle AYNI dekont
/// numarasını taşıyor. Referansı kesin eşitlik anahtarı yapmak, 85 satırlık o
/// ekstrede 3 gerçek hareketi "tekrar" işaretleyip seçimden düşürüyordu
/// (sessiz veri kaybı).
///
/// Referansın rolü bu yüzden yalnız AYIRICI: aynı gün, aynı tutar ve aynı
/// açıklamayla yapılmış GERÇEKTEN iki ayrı hareketi (gerçek ekstrede aynı gün
/// iki kez 40,00 TL "KARACA OTOMAT") artık birbirinden ayırabiliyoruz. Yani
/// referans yanlış-pozitif tekrarı azaltabilir, asla yenisini yaratamaz.
///
/// İki ayrı karşılaştırma yapılır:
///  1. **Dosya içi** — referans dahil bileşik anahtarla.
///  2. **Mevcut cüzdana karşı** — referanssız temel anahtarla: kayıtlı
///     işlemlerde banka referansı SAKLANMIYOR (`TransactionEntity`'de böyle bir
///     alan yok), dolayısıyla geçmişle karşılaştırmada kullanılamaz.
///
/// Eşleşen taslak `isDuplicate=true, selected=false` döner (kullanıcı isterse
/// incelemede yeniden işaretler). Muhafazakâr: fazladan tekrar işaretlemez,
/// eksik kalanı kullanıcı görür.
library;

import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

List<ImportDraft> markDuplicateDrafts(
  List<ImportDraft> drafts,
  List<TransactionEntity> existing,
) {
  final seen = <String>{
    for (final t in existing) _key(t.date, t.amount, t.isExpense, t.title),
  };

  final result = <ImportDraft>[];
  final withinFile = <String>{};

  for (final d in drafts) {
    final key = _key(d.date, d.amount, d.type.name == 'expense', d.description);
    final reference = d.reference?.trim() ?? '';
    final fileKey = '$key|$reference';

    final isDup = seen.contains(key) || withinFile.contains(fileKey);
    withinFile.add(fileKey);

    result.add(isDup ? d.copyWith(isDuplicate: true, selected: false) : d);
  }
  return result;
}

String _key(DateTime date, double amount, bool isExpense, String desc) {
  final day = DateTime(date.year, date.month, date.day).toIso8601String();
  final cents = (amount.abs() * 100).round() * (isExpense ? -1 : 1);
  final normDesc = desc.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return '$day|$cents|$normDesc';
}
