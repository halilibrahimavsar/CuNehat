import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:cunehat/features/bank_import/data/card_statement_parser.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/link_hint.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/data/statement_closing.dart';
import 'package:cunehat/features/bank_import/data/statement_verification.dart';
import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';

/// Banka ekstresi içe aktarma akış durumları. Bilerek Equatable DEĞİL: inceleme
/// mutasyonlarında her yeni örnek yeniden çizim tetiklemeli.
sealed class BankImportState {
  const BankImportState();
}

/// Başlangıç: hedef cüzdan + format seçimi + dosya seç.
class BankImportInitial extends BankImportState {
  const BankImportInitial();
}

/// Dosya okunuyor/ayrıştırılıyor.
class BankImportParsing extends BankImportState {
  const BankImportParsing();
}

/// CSV/Excel: kolon eşleme adımı. Yalnız otomatik eşlemeye güvenilemediğinde
/// (ya da kullanıcı incelemeden geri döndüğünde) gösterilir; [assessment]
/// eşlemenin bu tabloda ne ürettiğini canlı olarak taşır.
class BankImportMapping extends BankImportState {
  final RawTable table;
  final MappingAssessment assessment;
  const BankImportMapping({required this.table, required this.assessment});

  ColumnMapping get mapping => assessment.mapping;
}

/// Ayrıştırılan taslaklarda bilinen ama kullanıcının o türdeki kategori
/// listesinde karşılığı olmayan gruplar bulundu: incelemeden ÖNCE kullanıcıya
/// onaylatılır. Onaylanmayanlar oluşturulmaz; ilgili taslaklar yine mevcut
/// varsayılana (türün ilk kategorisi) düşer — bu adım tamamen isteğe bağlıdır.
class BankImportCategorySuggestion extends BankImportState {
  final List<CategorySuggestion> suggestions;
  final List<ImportDraft> rawDrafts;
  final int skippedRows;
  const BankImportCategorySuggestion({
    required this.suggestions,
    required this.rawDrafts,
    required this.skippedRows,
  });
}

/// Hedef cüzdanın neden değiştirilmesinin önerildiği.
enum TargetSuggestionReason {
  /// Ekstrenin satırlarının belirgin bir kısmı BAŞKA bir cüzdanda birebir
  /// kayıtlı: büyük olasılıkla yanlış cüzdan seçildi (ya da ekstre ikinci kez
  /// başka bir cüzdana aktarılıyor).
  entriesElsewhere,

  /// Kart ekstresinin son 4 hanesi başka bir kart cüzdanınınkiyle aynı.
  cardNumber,

  /// Satır satır bakiye taşıyan bir HESAP ekstresi kart cüzdanına
  /// aktarılıyor; kartın ödendiği hesap öneriliyor.
  accountOnCard,

  /// Aynı biçimdeki (aynı başlıklı) ekstre daha önce başka cüzdana aktarıldı.
  usedBefore,
}

/// "Hedefi X yap" önerisi (inceleme ekranının en üstünde, tek dokunuşla).
class TargetSuggestion {
  final String walletId;

  /// Gösterilecek ad (kartlarda "Hesap › Kart").
  final String walletName;
  final TargetSuggestionReason reason;

  /// [TargetSuggestionReason.entriesElsewhere]: o cüzdanda birebir kayıtlı
  /// satır sayısı; diğerlerinde 0.
  final int matchCount;

  /// [TargetSuggestionReason.cardNumber]: kartın son 4 hanesi.
  final String? last4;

  const TargetSuggestion({
    required this.walletId,
    required this.walletName,
    required this.reason,
    this.matchCount = 0,
    this.last4,
  });
}

/// Taslaklar hazır: inceleme (liste ya da stepper) + toplu ekleme.
class BankImportReview extends BankImportState {
  final List<ImportDraft> drafts;
  final List<CategoryEntity> expenseCategories;
  final List<CategoryEntity> incomeCategories;
  final int skippedRows;

  /// Bakiye sütunuyla mutabakat sonucu. Bakiye sütunu yoksa `null`.
  /// `matched` → işaretler bakiyeden türetildi (güven yüksek);
  /// `mismatch` → bakiye var ama tutmadı, kullanıcı kontrol etmeli.
  final BalanceReconciliation? reconciliation;

  /// Ekstrenin KENDİ beyanlarıyla yapılan aritmetik doğrulama (bakiye zinciri,
  /// "N kayıt bulunmuştur", devreden/kapanış bakiyesi, Borç/Alacak toplamları).
  /// Kullanıcıya "muhtemelen doğru" değil, kanıtlanmış bir sonuç göstermek
  /// için — bkz. [StatementVerification].
  final StatementVerification verification;

  /// Ekstrede sezilen para birimi hedef cüzdanınkinden farklıysa dolu gelir
  /// (uyarı için); aksi halde `null`.
  final String? foreignCurrency;

  /// Hedef cüzdanın para birimi — tutarların biçimlendirilmesi için HER ZAMAN
  /// doldurulur (cüzdan okunamazsa `null`).
  final String? walletCurrency;

  /// Kaynak dosyanın bütünlüğü şüpheli: akış beklenen kapanışla bitmedi
  /// (`.xls` yolunda) → bazı hareketler hiç okunmamış olabilir.
  final bool sourceTruncated;

  /// Kaydı okunduğu hâlde değeri çözülemeyen hücre sayısı — boş görünen bazı
  /// hücreler aslında veri taşıyordu.
  final int sourceUnresolvedCells;

  /// Taslaklar OCR'dan (ekran görüntüsü / taranmış PDF) çıkarıldı. Bu yolda
  /// tutarlarda karakter karışması (`,`↔`.`, `1`↔`7`) tipiktir ve görüntüde
  /// bakiye sütunu çoğu zaman bulunmadığı için mutabakat güvenlik ağı da
  /// devrede olmaz — kullanıcı ayrıca uyarılır.
  final bool fromOcr;

  /// Taslaklar bir CSV/Excel tablosundan geldi: inceleme ekranı "sütunları
  /// yeniden eşle" ile eşleme adımına dönebilir.
  final bool canRemap;

  /// Ekstre döneminde defterde duran ama hiçbir satırla eşleşmemiş, olası
  /// eşi olan kayıtlar (bkz. `findLedgerLeftovers`). Öneridir: hiçbir satırın
  /// seçimini değiştirmez; kullanıcı eşleştirir ya da kapatır. Her mutasyonda
  /// taslaklardan yeniden hesaplanır.
  final List<LedgerLeftover> leftovers;

  /// Kredi kartı ekstresiyse bankanın künyesi; banka ekstresinde `null`.
  final CardStatementFacts? cardFacts;

  /// Hedef cüzdan kredi kartı mı (künye aktarımda karta yazılır).
  final bool targetIsCard;

  /// Hedef cüzdan için daha uygun görünen cüzdan; yoksa `null`.
  final TargetSuggestion? targetSuggestion;

  /// Satır satır bakiye taşıyan bir hesap ekstresi kart cüzdanına
  /// aktarılıyor (öneri olmasa da uyarılır: kartın ödendiği hesap
  /// tanımlanmamış olabilir).
  final bool accountStatementOnCard;

  const BankImportReview({
    required this.drafts,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.skippedRows,
    this.reconciliation,
    this.verification = StatementVerification.none,
    this.foreignCurrency,
    this.walletCurrency,
    this.sourceTruncated = false,
    this.sourceUnresolvedCells = 0,
    this.fromOcr = false,
    this.canRemap = false,
    this.leftovers = const [],
    this.cardFacts,
    this.targetIsCard = false,
    this.targetSuggestion,
    this.accountStatementOnCard = false,
  });

  int get selectedCount => drafts.where((d) => d.selected).length;

  /// Olası eşi olan karşılıksız kayıtların adayı olan satırlar.
  Set<int> get leftoverCandidateIndexes => {
        for (final l in leftovers)
          for (final c in l.candidates) c.draftIndex,
      };
  int get duplicateCount => drafts.where((d) => d.isDuplicate).length;

  /// Elle girilmiş bir kayda YAKLAŞIK benzediği için (tahminle) seçimsiz
  /// gelen ve hâlâ eklenmeyecek satırlar — inceleme ekranında ayrıca uyarılır,
  /// çünkü bu kararı kanıt değil tahmin veriyor.
  int get approximateSkippedCount => drafts
      .where((d) => !d.selected && (d.duplicateOf?.isApproximate ?? false))
      .length;

  /// Defterdeki eşinin tutarı ekstredekiyle düzeltilecek satırlar.
  int get correctionCount =>
      drafts.where((d) => d.correctExisting && !d.selected).length;

  /// "Hepsini düzelt" toplu eyleminin kapsayacağı satırlar.
  int get correctableCount => drafts
      .where((d) =>
          !d.selected &&
          !d.correctExisting &&
          (d.duplicateOf?.isApproximate ?? false) &&
          d.duplicateOf!.canCorrectAmount)
      .length;

  /// Kategori tahmin edilemediği için boş kalan (kullanıcının elle
  /// seçmesi gereken) taslak sayısı — bkz. `CategoryGuesser.guess`: yanlış
  /// bir varsayılana (ör. hep ilk kategoriye) sessizce düşmek yerine
  /// tahmin yoksa `categoryId` bilerek `null` bırakılır.
  int get uncategorizedCount => drafts.where((d) => d.needsCategory).length;

  /// Kategorisi yalnız bankanın genel etiketinden tahmin edilen satırlar —
  /// en zayıf kanıt (bkz. [CategorySource.bankTag]); "Kontrol et" süzgeci.
  int get toCheckCount => drafts
      .where((d) =>
          d.categoryId != null && d.categorySource == CategorySource.bankTag)
      .length;

  /// Defterde BİREBİR kayıtlı olduğu için eklenmeyecek satır mı. Bu satırlar
  /// listede varsayılan olarak tek bir satıra katlanır: ardışık ekstrelerde
  /// her örtüşen satır ayrı bir "zaten kayıtlı" paneli çiziyordu.
  ///
  /// DEFTERE DOKUNACAK satır "bilinen" sayılmaz ve katlanmaz: tutarı
  /// düzeltilecek kayıt ve doğru aya taşınabilecek eski taksit satırı
  /// (bkz. `DuplicateMatch.legacyInstallment`). Katlansalardı kullanıcı
  /// defterinin değişeceğini görmeden "İçe aktar"a basardı.
  static bool isKnown(ImportDraft d) =>
      !d.selected &&
      d.duplicateOf?.kind == DuplicateKind.exact &&
      !d.correctExisting &&
      !(d.duplicateOf?.legacyInstallment ?? false);

  int get knownCount => drafts.where(isKnown).length;

  /// Ekstrenin TAMAMI defterde birebir kayıtlı: eklenecek yeni hareket yok.
  bool get allKnown => drafts.isNotEmpty && drafts.every(isKnown);

  /// Seçili (eklenecek) satırların gider/gelir toplamı. Eklemeden önce
  /// ekstrenin kendi toplamlarıyla karşılaştırmak için alt çubukta durur.
  double get selectedExpenseTotal => drafts
      .where((d) => d.selected && !d.isIncome)
      .fold(0.0, (sum, d) => sum + d.amount);
  double get selectedIncomeTotal => drafts
      .where((d) => d.selected && d.isIncome)
      .fold(0.0, (sum, d) => sum + d.amount);

  /// İÇE AKTARILACAK (seçili) ama kategorisi olmayan taslak sayısı.
  ///
  /// Kategori elle girişte zorunludur; kategorisiz bir hareket deftere boş
  /// `tag` ile yazılır ve bütçe/rapor hiçbir kategoriye saymaz — yani sessizce
  /// kaybolur. Bu yüzden [canCommit] bunu bir kapı olarak kullanır: sayı sıfır
  /// olmadan ekleme yapılmaz.
  ///
  /// Transfer olarak işaretli satır sayılmaz: o bir harcama/gelir değildir,
  /// kategorisi olmaz (bkz. [ImportDraft.transferWalletId]).
  int get selectedUncategorizedCount =>
      drafts.where((d) => d.selected && d.needsCategory).length;

  /// Toplu yazım yapılabilir mi: eklenecek ya da düzeltilecek en az bir satır
  /// var ve eklenecek satırların hepsi kategorili (düzeltilen kayıt zaten
  /// kendi kategorisini taşır).
  bool get canCommit =>
      (selectedCount > 0 || correctionCount > 0) &&
      selectedUncategorizedCount == 0;

  /// [expenseCategories]/[incomeCategories] yalnız inceleme sırasında yeni bir
  /// kategori oluşturulduğunda değişir (bkz. `BankImportCubit`).
  BankImportReview copyWith({
    List<ImportDraft>? drafts,
    List<CategoryEntity>? expenseCategories,
    List<CategoryEntity>? incomeCategories,
    List<LedgerLeftover>? leftovers,
  }) =>
      BankImportReview(
        drafts: drafts ?? this.drafts,
        expenseCategories: expenseCategories ?? this.expenseCategories,
        incomeCategories: incomeCategories ?? this.incomeCategories,
        skippedRows: skippedRows,
        reconciliation: reconciliation,
        verification: verification,
        foreignCurrency: foreignCurrency,
        walletCurrency: walletCurrency,
        sourceTruncated: sourceTruncated,
        sourceUnresolvedCells: sourceUnresolvedCells,
        fromOcr: fromOcr,
        canRemap: canRemap,
        leftovers: leftovers ?? this.leftovers,
        cardFacts: cardFacts,
        targetIsCard: targetIsCard,
        targetSuggestion: targetSuggestion,
        accountStatementOnCard: accountStatementOnCard,
      );
}

/// Toplu yazım ilerlemesi.
class BankImportCommitting extends BankImportState {
  final int done;
  final int total;
  const BankImportCommitting({required this.done, required this.total});
}

/// Bitti: eklenen + atlanan (seçilmeyen) sayıları. [walletId]/[userId], hedef
/// cüzdanı bulmak/aktif yapmak için. [balance], `syncBalance` sonrası defterden
/// TAZE okunan bakiye — UI'nin box-watch debounce'una (WalletBloc'un ~150ms
/// gecikmeli akışına) bağımlı kalıp anlık bayat bakiye göstermemesi için
/// durumda taşınır. [hasPastMonthRows], eklenen hareketlerin bir kısmı içinde
/// bulunulan ay dışında (liste varsayılanı mevcut ay) → kullanıcıyı uyar.
class BankImportDone extends BankImportState {
  final int added;

  /// Tutarı ekstredekiyle düzeltilen (yeni kayıt açılmayan) defter kaydı sayısı.
  final int corrected;

  /// Doğru aya TAŞINAN eski biçimli taksit satırı sayısı (bkz.
  /// `ImportDraft.relocateExisting`).
  final int relocated;
  final int skipped;
  final String walletId;
  final String userId;
  final double balance;
  final bool hasPastMonthRows;

  /// Kaydederken çözülmemiş kalan "karşılığı bulunamayan kayıt" önerisi
  /// sayısı. Sıfır değilse bakiye eşitlemesinden önce uyarılır: eşitleme
  /// açılış bakiyesini kaydırır ve bir tekrarı bakiyede görünmez yapar
  /// (rapor ise onu yine iki kez sayar).
  final int unresolvedLeftovers;

  /// Yazılan satırlardan bir kayda (birikim, borç ödemesi, kredi girişi)
  /// bağlanmaya aday görünenler — yalnız öneri (bkz. `linkHintOf`).
  final List<LinkSuggestion> linkSuggestions;

  /// Kart ekstresinin künyesi hedef kartın "son ekstresi" olarak yazıldı mı.
  final bool cardStatementSaved;

  /// Taksitli alışverişlerin İLERİ tarihe yazılan kalan taksit sayısı
  /// ([added]'e dahil DEĞİL: ekstrede satır olarak yoklardı).
  final int futureInstallments;

  /// İnceleme ekranında transfer olarak işaretlenip yazılırken BAĞLANAN satır
  /// sayısı ([added]'e dahildir).
  final int linkedTransfers;

  /// Eklenen hareketlerin en eski ve en yeni tarihi ("Eklenenleri göster"
  /// işlem listesini bu aralıkla açar); hiçbir şey eklenmediyse `null`.
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Ekstrenin kendi beyan ettiği kapanış bakiyesi (bakiye zinciri
  /// kanıtlanmış hesap ekstresinde); yoksa `null`.
  final StatementClosing? closing;

  /// Cüzdanın [closing] tarihindeki defter bakiyesi. Bugünkü bakiyeyle değil
  /// bununla kıyaslanır: ekstreden SONRA girilmiş işlemler bugünkü bakiyeyi
  /// ekstreninkinden zaten ayırır, bu bir tutarsızlık değildir.
  final double? ledgerAtClosing;

  const BankImportDone({
    required this.added,
    this.corrected = 0,
    this.relocated = 0,
    required this.skipped,
    required this.walletId,
    required this.userId,
    required this.balance,
    required this.hasPastMonthRows,
    this.unresolvedLeftovers = 0,
    this.linkSuggestions = const [],
    this.cardStatementSaved = false,
    this.futureInstallments = 0,
    this.linkedTransfers = 0,
    this.firstDate,
    this.lastDate,
    this.closing,
    this.ledgerAtClosing,
  });

  /// Bankanın kapanış bakiyesi ile defterin o günkü bakiyesi arasındaki fark
  /// (banka − defter, kuruşa yuvarlı); kıyas yapılamıyorsa `null`.
  double? get closingDifference {
    final c = closing;
    final l = ledgerAtClosing;
    if (c == null || l == null) return null;
    return ((c.amount - l) * 100).round() / 100;
  }
}

/// Geçmişteki bir ekstre içe aktarımı ("Son içe aktarımlar" listesi). Aynı
/// `importBatchId`'yi taşıyan işlemlerden kurulur; ayrı bir kayıt tutulmaz.
class ImportBatch {
  final String id;
  final String walletId;
  final String walletName;

  /// Defterde hâlâ duran satır sayısı (bu arada silinenler düşer).
  final int count;

  /// İçe aktarımın yapıldığı an (UUIDv7 kimliğinin içinden okunur).
  final DateTime importedAt;
  final DateTime firstDate;
  final DateTime lastDate;

  const ImportBatch({
    required this.id,
    required this.walletId,
    required this.walletName,
    required this.count,
    required this.importedAt,
    required this.firstDate,
    required this.lastDate,
  });
}

/// "İçe aktarımı geri al"ın sonucu. Geri alma diyaloğu sonucu sayılarıyla
/// anlatır: kullanıcı neyin silindiğini, neyin yerinde kaldığını görmeli.
class ImportUndoResult {
  /// Silinen (az önce eklenmiş) işlem sayısı.
  final int removed;

  /// Eski tutarına döndürülen (düzeltilmiş) defter kaydı sayısı.
  final int reverted;

  /// Bu arada bir kayda BAĞLANDIĞI için yerinde bırakılan satır sayısı.
  final int kept;

  /// Kartın "son ekstre" bilgisi içe aktarım öncesine döndü mü.
  final bool cardStatementReverted;

  const ImportUndoResult({
    this.removed = 0,
    this.reverted = 0,
    this.kept = 0,
    this.cardStatementReverted = false,
  });

  static const none = ImportUndoResult();
}

class BankImportError extends BankImportState {
  final String message;
  const BankImportError(this.message);
}

/// PDF metni çıkarıldı ama hareket satırı tanınamadı: ham metin tanılama için
/// gösterilir (kullanıcı paylaşınca ayrıştırıcı o düzene uyarlanabilir).
class BankImportRawText extends BankImportState {
  final String rawText;
  const BankImportRawText(this.rawText);
}

/// PDF'in metin katmanı YOK (taranmış sayfa / fotoğraf / ekran görüntüsünden
/// üretilmiş belge). [BankImportRawText]'ten ayrı bir durum, çünkü gösterilecek
/// ham metin de yok: kullanıcıya boş bir kutu göstermek yerine neden okunamadığı
/// ve ne yapabileceği söylenir.
class BankImportScannedPdf extends BankImportState {
  const BankImportScannedPdf();
}

/// Eski ikili Excel (.xls) okunmaya çalışıldı ama AÇILAMADI (parola, BIFF5 gibi
/// daha eski sürüm, bozuk kap). [reason] kullanıcıya gösterilecek kısa neden;
/// çözüm her hâlde aynı: dosyayı .xlsx olarak kaydet ya da CSV indir.
class BankImportLegacyExcel extends BankImportState {
  final String reason;
  const BankImportLegacyExcel(this.reason);
}

/// Seçilen dosyanın biçimi ne imzadan ne uzantıdan tanınabildi.
class BankImportUnsupportedFile extends BankImportState {
  const BankImportUnsupportedFile();
}
