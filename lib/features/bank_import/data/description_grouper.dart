import 'package:cunehat/core/utils/label_grouper.dart';
export 'package:cunehat/core/utils/label_grouper.dart' show kMinGroupSize;
import 'package:cunehat/features/bank_import/domain/import_draft.dart';

/// Açıklamaları birbirine benzeyen taslakların kümesi.
///
/// [indexes] KAYNAK listedeki gerçek indekslerdir: inceleme ekranının tüm
/// mutasyonları indeks tabanlı olduğu için grup, üzerinde çalıştığı listeyle
/// birlikte taşınmak zorunda (bkz. `BankImportReviewView._visible`).
typedef DraftGroup = ({
  /// Ortak adın katlanmış hâli — kimlik ve karşılaştırma için.
  String key,

  /// Kullanıcıya gösterilecek ortak ad, ekstredeki ÖZGÜN yazımıyla.
  String label,

  /// Grubun türü. Gruplar tür bazında ayrılır: gider kategorisi gelir
  /// satırına yazılamaz, dolayısıyla karışık bir gruba tek kategori
  /// atanamazdı.
  bool isIncome,

  /// Kaynak listedeki indeksler, artan sırada.
  List<int> indexes,

  /// Gruptaki tutarların toplamı (mutlak; yön [isIncome] ile taşınır).
  double totalAmount,
});

/// [drafts] içindeki benzer açıklamaları gruplar.
///
/// Kümeleme motoru — ön ek ağacı, gürültü kelimeleri, kod eşiği ve ölçülmüş
/// sınırları — `core/utils/label_grouper.dart`'ta ORTAKTIR; rapor sayfasının
/// "en çok harcanan yer" kartı da onu kullanır. Buradaki iş yalnız taslakları
/// o motorun kayıt biçimine çevirmek ve sonucu ekstre sözlüğüne geri
/// döndürmek.
List<DraftGroup> groupSimilarDrafts(
  List<ImportDraft> drafts, {
  Iterable<int>? scope,
  int minSize = kMinGroupSize,
}) {
  final groups = groupSimilarLabels(
    [
      for (final d in drafts)
        (text: d.description, amount: d.amount, bucket: d.isIncome ? 1 : 0),
    ],
    scope: scope,
    minSize: minSize,
  );

  return [
    for (final g in groups)
      (
        key: g.key,
        label: g.label,
        isIncome: g.bucket == 1,
        indexes: g.indexes,
        totalAmount: g.totalAmount,
      ),
  ];
}

/// [drafts] içinde [index] satırına benzeyen DİĞER satırların indeksleri.
/// Benzer yoksa boş liste. Satır bazında "bunun benzerlerine de uygula"
/// kısayolu için.
List<int> similarDraftIndexes(List<ImportDraft> drafts, int index) {
  for (final group in groupSimilarDrafts(drafts)) {
    if (group.indexes.contains(index)) {
      return [
        for (final i in group.indexes)
          if (i != index) i,
      ];
    }
  }
  return const [];
}
