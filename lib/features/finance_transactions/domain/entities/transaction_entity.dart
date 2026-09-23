import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:equatable/equatable.dart';

/// [TransactionEntity.origin] değerleri: kaydın nereden geldiği.
///
/// Metin olarak saklanır (enum sırası değil): bilinmeyen/yeni bir değer
/// eski sürümde okunamaz hâle gelmesin.
abstract final class TransactionOrigin {
  /// İşlem formundan elle girildi.
  static const String manual = 'manual';

  /// Banka ekstresinden içe aktarıldı.
  static const String bankImport = 'import';

  /// Düzenli işlem şablonunun onayıyla oluştu.
  static const String recurring = 'recurring';

  /// CSV içe aktarımıyla geldi.
  static const String csv = 'csv';
}

class TransactionEntity extends Equatable {
  final String? id;
  final String userId;
  final String walletId;
  final String title;
  final String tag;
  final double amount;
  final DateTime date;
  final TransactionTypeModel type;

  /// Borç/yatırım/alacak/transfer kuplajının hareketi: kuplajın kendisinin
  /// yazdığı ya da kullanıcının düz bir satırından BENİMSENDİĞİ (bkz.
  /// [adoptedFromTag]) işlem. Listede elle silinemez/düzenlenemez (defterle
  /// desync olmasın); ilgili kayıttan yönetilir.
  final bool isSystem;

  /// İşleme iliştirilmiş fiş/fotoğraf görselinin dosya ADI (mutlak yol değil).
  /// Görsel `belgelerDizini/receipts/<receiptFileName>` altında saklanır; mutlak
  /// yol reinstall/cihaz değişince değişeceği için yalnız ad tutulur. Görsel
  /// binary'si yedeğe girmez — yalnız bu ad taşınır (yeni cihazda dosya yoksa
  /// "görsel bu cihazda yok" gösterilir). Ek yoksa null.
  final String? receiptFileName;

  /// Bankanın bu harekete verdiği kendi numarası (Dekont No / Fiş No / İşlem
  /// No) — yalnız banka ekstresinden içe aktarılan işlemlerde dolu.
  ///
  /// **Neden defterde tutuluyor:** içe aktarımlar arası "bu hareketi zaten
  /// aldım mı" sorusunun tek KESİN yanıtı budur. Alternatif kimlik
  /// (gün + tutar + başlık) iki yönden de kırılgan: başlık kullanıcı
  /// tarafından düzenlenebilir (inceleme ekranı bunu zaten yaptırıyor) ve
  /// gerçek ekstrelerde aynı gün, aynı tutar, aynı açıklamalı FARKLI
  /// hareketler bulunuyor (ölçüldü: bir Garanti ekstresinde 2 çift —
  /// "KARACA OTOMAT" 40,00 ve "MACGAL GIDA" 30,00). Banka numarası ise
  /// değişmez. Bkz. `markDuplicateDrafts`.
  ///
  /// Elle girilen işlemlerde ve referans sütunu olmayan ekstrelerde `null`.
  final String? reference;

  /// Bu hareketin SAHİBİ olan alan kaydı — yalnız kuplaj hareketlerinde
  /// ([isSystem]) dolu: yatırım kimliği, borç ödemesinin (`Payment`)
  /// kimliği, borcun kendisi (anapara), alacak kimliği ya da transfer
  /// çiftinin ortak kimliği. Bu alandan önce yazılmış kuplaj hareketlerinde
  /// `null` (sahibi bilinmiyordu).
  final String? linkedRecordId;

  /// Yalnız BENİMSENMİŞ harekette dolu: kullanıcının düz bir satırı (çoğu
  /// zaman ekstreden gelen) yeni bir hareket yazılmadan bir alan kaydının
  /// nakit bacağı yapıldığında satırın özgün kategorisi.
  ///
  /// **Neden saklanıyor:** kayıt "hatalı giriş" diye silinince satır bu
  /// kategoriyle DÜZ satıra geri döner. Bankada para gerçekten çıktı; ters
  /// kayıt (düzeltme geliri) yazmak cüzdanı bankadan koparırdı.
  final String? adoptedFromTag;

  /// Kaydın nereden geldiği ([TransactionOrigin]); kuplaj hareketlerinde ve
  /// bu alandan önce yazılmış kayıtlarda `null`.
  ///
  /// **Neden:** ekstre tekrar tespiti "bu kayıt başka bir ekstreden mi
  /// gelmiş" sorusunu eskiden yalnız başlığın yazımından TAHMİN ediyordu
  /// (büyük harf / 4+ rakam) — elle "MIGROS" ya da "Kira 2026" yazan
  /// kullanıcının kaydı ekstreden gelmiş sanılıp bulunamıyordu.
  final String? origin;

  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.title,
    required this.tag,
    required this.amount,
    required this.date,
    required this.type,
    this.isSystem = false,
    this.receiptFileName,
    this.reference,
    this.linkedRecordId,
    this.adoptedFromTag,
    this.origin,
  });

  /// Kullanıcının düz satırı bir alan kaydına benimsenmiş mi (bkz.
  /// [adoptedFromTag]).
  bool get isAdopted => adoptedFromTag != null;

  TransactionEntity copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? title,
    String? tag,
    double? amount,
    DateTime? date,
    TransactionTypeModel? type,
    bool? isSystem,
    String? receiptFileName,
    String? reference,
    String? linkedRecordId,
    String? adoptedFromTag,
    String? origin,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      isSystem: isSystem ?? this.isSystem,
      receiptFileName: receiptFileName ?? this.receiptFileName,
      reference: reference ?? this.reference,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      adoptedFromTag: adoptedFromTag ?? this.adoptedFromTag,
      origin: origin ?? this.origin,
    );
  }

  /// Benimsenmiş hareketi özgün DÜZ satırına döndürür: sistem işareti,
  /// sahip bağı ve benimseme izi kalkar, kategori [adoptedFromTag]'e döner.
  /// Başlık, tarih, tutar, banka numarası ve fiş olduğu gibi kalır.
  ///
  /// [copyWith] bunu yapamaz (`??` deseni alanları `null`'a çekemez).
  TransactionEntity released() => TransactionEntity(
        id: id,
        userId: userId,
        walletId: walletId,
        title: title,
        tag: adoptedFromTag ?? tag,
        amount: amount,
        date: date,
        type: type,
        receiptFileName: receiptFileName,
        reference: reference,
        origin: origin,
      );

  /// Düzenleme formunun ürettiği kayıt: formun gösterdiği alanlar yeni
  /// değerlerle, formda OLMAYAN alanlar (kimlik, cüzdan, [isSystem],
  /// [reference]) bu kayıttan taşınır.
  ///
  /// [copyWith] burada yetmez: fişi kaldırmak [receiptFileName]'i `null`'a
  /// çekmeyi gerektirir, `??` deseni buna izin vermez. Form eskiden varlığı
  /// sıfırdan kuruyordu ve formda olmayan alanlar sessizce siliniyordu: içe
  /// aktarılmış bir işlemin yalnız kategorisini değiştirmek bankanın
  /// numarasını kaybettiriyordu — içe aktarımlar arası tekrar tespitinin en
  /// güçlü kimliği (bkz. `markDuplicateDrafts`). Yeni alan eklenince buraya
  /// da eklenmeli.
  TransactionEntity edited({
    required String title,
    required String tag,
    required double amount,
    required DateTime date,
    required TransactionTypeModel type,
    required String? receiptFileName,
  }) =>
      TransactionEntity(
        id: id,
        userId: userId,
        walletId: walletId,
        title: title,
        tag: tag,
        amount: amount,
        date: date,
        type: type,
        isSystem: isSystem,
        receiptFileName: receiptFileName,
        reference: reference,
        linkedRecordId: linkedRecordId,
        adoptedFromTag: adoptedFromTag,
        origin: origin,
      );

  bool get isIncome => type == TransactionTypeModel.income;
  bool get isExpense => type == TransactionTypeModel.expense;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'title': title,
      'tag': tag,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
      'isSystem': isSystem,
      'receiptFileName': receiptFileName,
      'reference': reference,
      'linkedRecordId': linkedRecordId,
      'adoptedFromTag': adoptedFromTag,
      'origin': origin,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        title,
        tag,
        amount,
        date,
        type,
        isSystem,
        receiptFileName,
        reference,
        linkedRecordId,
        adoptedFromTag,
        origin,
      ];
}
