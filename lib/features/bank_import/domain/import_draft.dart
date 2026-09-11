import 'package:equatable/equatable.dart';

import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';

/// Bir taslağın neyin tekrarı sanıldığı.
enum DuplicateKind {
  /// Defterde gün + kuruşu kuruşuna tutar + (referans ya da açıklama) aynı bir
  /// kayıt var — büyük olasılıkla aynı ekstre ikinci kez içe aktarılıyor.
  exact,

  /// Defterde BİREBİR değil ama çok benzeyen bir kayıt var: tipik olarak
  /// kullanıcının aynı harcamayı elle, yaklaşık tutarla (913,15 yerine 913
  /// ya da 910) ve saatine/gününe dikkat etmeden girmiş olması. Bu bir
  /// TAHMİNDİR; gerekçeleri [DuplicateMatch] alanlarında taşınır ve inceleme
  /// ekranında tek tek gösterilir.
  approximate,

  /// Aynı dosyada aynı gün/tutar/açıklamayla ikinci kez geçiyor (defterle
  /// ilgisi yok). Yalnız satırların ayrı hareketler olduğu KANITLANAMADIĞINDA
  /// işaretlenir — bakiye zinciri tutan bir ekstrede her satır bakiyeyi
  /// değiştirdiği için tekrar olamaz.
  withinFile,
}

/// Elle girilen tutarın banka tutarına nasıl benzediği (yaklaşık eşleşmenin
/// tutar gerekçesi). Yalnız YUVARLAMA kalıpları kabul edilir: "kullanıcı
/// yaklaşık yazdı" varsayımının kendisi bu. Rastgele bir fark (913,15 ↔
/// 931,00) eşleşme sayılmaz.
enum AmountPattern {
  /// Kuruşu kuruşuna aynı.
  exact,

  /// Elle girilen tutar tam sayı ve farkı 1 birimden az (913,15 → 913).
  centsDropped,

  /// 5'e ya da 10'a yuvarlanmış (913,15 → 915 / 910).
  roundedSmall,

  /// 50'ye ya da 100'e yuvarlanmış (1.478,90 → 1.500) — yalnız büyük
  /// tutarlarda, göreli fark küçük kalsın diye.
  roundedLarge,
}

/// Taslağın defterdeki (ya da dosyadaki) olası eşi ve eşleşmenin
/// GEREKÇELERİ. Kullanıcıya "bu satır neden eklenmeyecek" sorusunun cevabı
/// buradan çizilir; eşleşmenin kendisi bir yargı değil öneridir.
class DuplicateMatch extends Equatable {
  final DuplicateKind kind;

  /// Eşleşen defter kaydının kimliği; [DuplicateKind.withinFile] için `null`.
  final String? existingId;
  final String existingTitle;

  /// Eşleşen kaydın kategori kimliği (defter kaydıysa); dosya içi eşte `null`.
  final String? existingTag;
  final double existingAmount;
  final DateTime existingDate;

  /// Borç/yatırım kuplajının kaydı: düzenlenemez, yalnız "ekleme" kararı
  /// verilebilir (tutarı düzeltilemez).
  final bool existingIsSystem;

  /// Taslak tutarı − eşleşen kaydın tutarı (kuruşa yuvarlı).
  final double amountDelta;
  final AmountPattern amountPattern;

  /// |taslak günü − kayıt günü|.
  final int dayDistance;

  /// İki metinde de geçen, üye işyerini gösteren bir kelime (varsa) —
  /// kaydın kendi yazımıyla ("bim").
  final String? sharedWord;

  /// Taslağın tahmin edilen kategorisi, kaydın kategorisiyle (ya da onun ana
  /// kategorisiyle) aynı mı.
  final bool categoryMatches;

  /// Yaklaşık eşleşmenin gücü; kesin ve dosya içi eşlerde her zaman `true`.
  final bool strong;

  const DuplicateMatch({
    required this.kind,
    required this.existingTitle,
    required this.existingAmount,
    required this.existingDate,
    this.existingId,
    this.existingTag,
    this.existingIsSystem = false,
    this.amountDelta = 0,
    this.amountPattern = AmountPattern.exact,
    this.dayDistance = 0,
    this.sharedWord,
    this.categoryMatches = false,
    this.strong = true,
  });

  bool get isApproximate => kind == DuplicateKind.approximate;

  /// Tutarı ekstredekiyle düzeltmek anlamlı mı: defterde düzenlenebilir bir
  /// kayıt var ve tutarlar gerçekten farklı.
  bool get canCorrectAmount =>
      existingId != null && !existingIsSystem && amountDelta.abs() >= 0.005;

  @override
  List<Object?> get props => [
        kind,
        existingId,
        existingTitle,
        existingTag,
        existingAmount,
        existingDate,
        existingIsSystem,
        amountDelta,
        amountPattern,
        dayDistance,
        sharedWord,
        categoryMatches,
        strong,
      ];
}

/// Banka ekstresinden çıkarılan tek bir hareket taslağı. Format-bağımsız ortak
/// birim: CSV/Excel (kolon eşleme) ve PDF (satır-sezgisel) yolları hep bunu üretir.
///
/// [amount] daima POZİTİF ve kuruşa yuvarlı; yön [type] ile taşınır (banka
/// ekstresinde işaret/borç-alacak ayrıştırıcıda çözülür). İnceleme adımında
/// [selected]/[type]/[categoryId] kullanıcı tarafından değiştirilebilir.
class ImportDraft extends Equatable {
  final DateTime date;
  final String description;
  final double amount;
  final TransactionTypeModel type;

  /// Atanan kategori (tag). Toplu varsayılandan gelir, satır bazında düzenlenir.
  final String? categoryId;

  /// Bankanın ekstrede verdiği KENDİ kategori etiketi ("Alışveriş",
  /// "Para Çekme", "Maaş"…). Yalnız kategori tahmininde ipucu olarak
  /// kullanılır; işleme yazılmaz. Ekstrede böyle bir sütun yoksa `null`.
  final String? sourceTag;

  /// Bankanın hareket referansı (dekont/fiş/işlem no). Ekstre içinde bir
  /// hareketi KESİN olarak tanımlar; gün+tutar+açıklama sezgisinin aksine
  /// kullanıcı düzenlemesinden ve biçim farklarından etkilenmez.
  /// Sütun yoksa `null`. Deftere de yazılır ([toEntity]) — içe aktarımlar
  /// ARASI tekrar tespiti buna dayanır (bkz. `markDuplicateDrafts`).
  final String? reference;

  /// Defterde ya da dosyada bulunan olası eşi; yoksa `null`.
  final DuplicateMatch? duplicateOf;

  /// İçe aktarılacak mı (tekrarlar varsayılan false gelir).
  final bool selected;

  /// Yeni kayıt açmak yerine eşleşen defter kaydının tutarı bu taslağın
  /// (bankanın) tutarıyla düzeltilecek. Yalnız [DuplicateMatch.canCorrectAmount]
  /// iken anlamlıdır ve [selected] ile birlikte `true` OLAMAZ: ya yeni kayıt
  /// eklenir ya eskisi düzeltilir.
  final bool correctExisting;

  const ImportDraft({
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    this.categoryId,
    this.sourceTag,
    this.reference,
    this.duplicateOf,
    this.selected = true,
    this.correctExisting = false,
  });

  bool get isIncome => type == TransactionTypeModel.income;
  bool get isDuplicate => duplicateOf != null;

  /// [duplicateOf] `copyWith` ile TEMİZLENEMEZ (`??` deseni); eşleşmeyi
  /// düşürmek için [withoutDuplicate] kullanılır.
  ImportDraft copyWith({
    DateTime? date,
    String? description,
    double? amount,
    TransactionTypeModel? type,
    String? categoryId,
    String? sourceTag,
    String? reference,
    DuplicateMatch? duplicateOf,
    bool? selected,
    bool? correctExisting,
  }) {
    return ImportDraft(
      date: date ?? this.date,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      sourceTag: sourceTag ?? this.sourceTag,
      reference: reference ?? this.reference,
      duplicateOf: duplicateOf ?? this.duplicateOf,
      selected: selected ?? this.selected,
      correctExisting: correctExisting ?? this.correctExisting,
    );
  }

  /// Eşleşmesi düşürülmüş kopya (düzeltme kararı da düşer).
  ImportDraft withoutDuplicate() => ImportDraft(
        date: date,
        description: description,
        amount: amount,
        type: type,
        categoryId: categoryId,
        sourceTag: sourceTag,
        reference: reference,
        selected: selected,
      );

  /// Toplu yazımda kalıcı işleme dönüştürür. [id] çağıran tarafından üretilir
  /// (UUIDv7); ham repo [id] null kabul etmez.
  ///
  /// Başlık boşsa [categoryName]'e düşer — kategori kimliği UUID olduğundan
  /// onu basmak başlığa anlamsız bir dizgi yazardı.
  TransactionEntity toEntity({
    required String id,
    required String userId,
    required String walletId,
    String? categoryName,
  }) {
    final title = description.trim().isEmpty
        ? (categoryName ?? 'İşlem')
        : description.trim();
    return TransactionEntity(
      id: id,
      userId: userId,
      walletId: walletId,
      title: title,
      tag: categoryId ?? '',
      amount: amount,
      date: date,
      type: type,
      isSystem: false,
      reference: reference,
    );
  }

  @override
  List<Object?> get props => [
        date,
        description,
        amount,
        type,
        categoryId,
        sourceTag,
        reference,
        duplicateOf,
        selected,
        correctExisting,
      ];
}
