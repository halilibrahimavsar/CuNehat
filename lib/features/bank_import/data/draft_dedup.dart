/// Taslakları, mevcut deftere ve dosyanın kendisine karşı olası tekrarlara
/// göre işaretler.
///
/// **İki kimlik, güç sırasıyla:**
///  1. **Güçlü anahtar** — `(gün, işaretli kuruş, banka referansı)`. Referans
///     (Dekont/Fiş/İşlem No) `TransactionEntity.reference` olarak deftere de
///     yazıldığı için (şema v5) artık İÇE AKTARIMLAR ARASI karşılaştırılabilir.
///     Başlık içermez: **kullanıcı başlığı düzenleyebilir** (inceleme ekranı
///     bunu zaten yaptırıyor) ve düzenlenmiş bir işlem yeniden aktarımda
///     ikinci kez yazılıyordu.
///  2. **Zayıf anahtar** — `(gün, işaretli kuruş, normalize başlık)`.
///     Referansı olmayan taraflar için: elle girilen işlemler ve referans
///     sütunu taşımayan ekstreler (ör. Garanti'nin PDF'i Dekont No vermez,
///     `.xls`'i verir — aynı hesabın iki biçimi birbirini yine bulmalı).
///
/// **Referans TEK BAŞINA anahtar DEĞİLDİR.** Gerçek bir Garanti ekstresinde
/// dekont numarası işlem başına değil OPERASYON başına veriliyor: bir havalenin
/// masraf satırı ("KESİNTİ VE EKLERİ") ana havaleyle AYNI numarayı taşıyor.
/// Tutar anahtara dahil olduğu için bu iki satır yine ayrışır.
///
/// **Eşleşme TÜKETİMLİDİR (sayaç, küme değil).** Eski sürüm defteri bir `Set`e
/// koyuyordu; aynı gün, aynı tutar, aynı açıklamalı İKİ GERÇEK hareket varsa
/// (ölçüldü: bir Garanti ekstresinde "KARACA OTOMAT" 40,00 ve "MACGAL GIDA"
/// 30,00 çiftleri) defterdeki tek kayıt ikisini birden "tekrar" işaretliyor,
/// ikinci gerçek hareket sessizce düşüyordu. Artık her defter kaydı yalnız BİR
/// taslağı eşleştirebilir.
///
/// **İki taraf da referans taşıyor ve güçlü anahtar tutmadıysa zayıf anahtara
/// düşülmez:** banka onlara ayrı numara verdiyse ayrı hareketlerdir.
///
/// Eşleşen taslak `isDuplicate=true, selected=false` döner (kullanıcı isterse
/// incelemede yeniden işaretler). Muhafazakâr: fazladan tekrar işaretlemez,
/// eksik kalanı kullanıcı görür.
library;

import 'package:cunehat/core/utils/text_search.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

List<ImportDraft> markDuplicateDrafts(
  List<ImportDraft> drafts,
  List<TransactionEntity> existing,
) {
  // Defterdeki her kayıt tek kullanımlık: eşleşince tüketilir.
  final pool = <_Existing>[];
  final byStrong = <String, List<_Existing>>{};
  final byWeak = <String, List<_Existing>>{};
  for (final t in existing) {
    final money = _money(t.date, t.amount, t.isExpense);
    final reference = _norm(t.reference);
    final entry = _Existing(hasReference: reference != null);
    pool.add(entry);
    if (reference != null) {
      (byStrong['$money|$reference'] ??= []).add(entry);
    }
    (byWeak['$money|${_normTitle(t.title)}'] ??= []).add(entry);
  }

  final result = <ImportDraft>[];
  final withinFile = <String>{};

  for (final d in drafts) {
    final money = _money(d.date, d.amount, !d.isIncome);
    final reference = _norm(d.reference);
    final weakKey = '$money|${_normTitle(d.description)}';

    // Dosya içi tekrar: referans yalnız AYIRICIDIR, yerine geçmez — aksi halde
    // dekontu paylaşan havale+masraf çifti tek satır sanılır.
    var isDuplicate = !withinFile.add('$weakKey|${reference ?? ''}');

    if (!isDuplicate) {
      final matched =
          (reference != null && _consume(byStrong['$money|$reference'])) ||
              // Referanslı bir taslak, referanslı FARKLI bir kayda zayıf
              // anahtardan bağlanamaz.
              _consume(byWeak[weakKey], skipReferenced: reference != null);
      isDuplicate = matched;
    }

    result
        .add(isDuplicate ? d.copyWith(isDuplicate: true, selected: false) : d);
  }
  return result;
}

/// Havuzdan ilk tüketilmemiş kaydı tüketir; bulduysa `true`.
bool _consume(List<_Existing>? candidates, {bool skipReferenced = false}) {
  if (candidates == null) return false;
  for (final c in candidates) {
    if (c.consumed) continue;
    if (skipReferenced && c.hasReference) continue;
    c.consumed = true;
    return true;
  }
  return false;
}

class _Existing {
  final bool hasReference;
  bool consumed = false;
  _Existing({required this.hasReference});
}

String? _norm(String? raw) {
  final s = raw?.trim();
  return (s == null || s.isEmpty) ? null : s;
}

String _money(DateTime date, double amount, bool isExpense) {
  final day = DateTime(date.year, date.month, date.day).toIso8601String();
  final cents = (amount.abs() * 100).round() * (isExpense ? -1 : 1);
  return '$day|$cents';
}

/// Zayıf anahtarın başlık parçası.
///
/// [foldTr] kullanılır, `toLowerCase()` DEĞİL: Dart noktasız `I`'yı `i`'ye
/// çevirir, `ı`'ya değil. Ekstre "IŞIK ELEKTRİK" yazar (`işik elektrik`),
/// kullanıcı elle "Işık Elektrik" girer (`ışık elektrik`) — iki taraf hiç
/// eşleşmez ve aynı hareket ikinci kez deftere yazılırdı. (Trim + iç
/// boşlukların teklenmesi [foldTr]'nin içinde.)
String _normTitle(String desc) => foldTr(desc);
