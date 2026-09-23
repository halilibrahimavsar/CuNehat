part of 'debt_bloc.dart';

abstract class DebtEvent extends Equatable {
  const DebtEvent();

  @override
  List<Object?> get props => [];
}

class GetDebtsEvent extends DebtEvent {
  final String walletId;
  const GetDebtsEvent(this.walletId);

  @override
  List<Object?> get props => [walletId];
}

class AddDebtEvent extends DebtEvent {
  final DebtEntity debt;

  /// Anaparanın cüzdana girişi nereden: yeni gelir (varsayılan) ya da
  /// defterde ZATEN duran satır — ekstredeki "KREDI KULLANDIRIM +50.000"
  /// gibi. İkincisinde satır benimsenir; ikinci bir gelir yazılmaz (eskiden
  /// anapara iki kez gelir sayılıyordu). Yalnız `principalToWallet` iken
  /// anlamlıdır.
  final CashSource principalSource;

  const AddDebtEvent(
    this.debt, {
    this.principalSource = const NewCashMovement(),
  });

  @override
  List<Object?> get props => [debt, principalSource];
}

class UpdateDebtEvent extends DebtEvent {
  final DebtEntity debt;
  final double prevPrincipal; // mutabakat için düzenleme öncesi anapara

  /// Düzenleme öncesi başlangıç tarihi. Anapara hareketi bu tarihte duruyor;
  /// tarih taşındıysa kayıt eski dönemde bırakılamaz (silmedeki ters kayıt
  /// YENİ tarihe yazılır ve iki dönem birden bozulurdu).
  final DateTime prevStartDate;

  const UpdateDebtEvent(
    this.debt, {
    required this.prevPrincipal,
    required this.prevStartDate,
  });

  @override
  List<Object?> get props => [debt, prevPrincipal, prevStartDate];
}

/// Borca ödeme yapıldığında: güncel borcu (yeni payment eklenmiş) kaydeder ve
/// [paymentAmount] kadar nakit gider işlemi oluşturur (nakit kuplajı).
class PayDebtEvent extends DebtEvent {
  final DebtEntity debt;
  final double paymentAmount;

  /// Kullanıcının seçtiği ödeme tarihi. Gider bu tarihe yazılır; silmedeki
  /// ters kayıt da `Payment.date`'i kullandığından iki bacak aynı dönemde
  /// kapanır. (Bugüne yazılırsa geçmiş tarihli ödeme bir dönemde gidersiz
  /// iade, başka dönemde iadesiz gider bırakıyordu.)
  final DateTime paymentDate;

  /// Yeni ödemenin ([debt] içindeki) kimliği: kuplaj hareketi ona bağlanır
  /// (`TransactionEntity.linkedRecordId`).
  final String? paymentId;

  /// Ödemenin nakit bacağı: yeni gider (varsayılan) ya da defterde zaten
  /// duran satır (ekstredeki "KREDI TAKSIT −2.500") — benimsenir.
  final CashSource cashSource;

  const PayDebtEvent(
    this.debt,
    this.paymentAmount, {
    required this.paymentDate,
    this.paymentId,
    this.cashSource = const NewCashMovement(),
  });

  @override
  List<Object?> get props =>
      [debt, paymentAmount, paymentDate, paymentId, cashSource];
}

/// Var olan bir ödeme kaydını günceller (tutar / tarih / not).
///
/// [debt] ödeme listesi GÜNCELLENMİŞ hâlidir; faiz payları ve `isPaid`
/// handler'daki tek normalizasyon noktasından geçer. Önceki tutar ve tarih
/// defter mutabakatı için ayrıca taşınır — kaydın kendisi zaten yeni hâlinde.
class UpdateDebtPaymentEvent extends DebtEvent {
  final DebtEntity debt;
  final double prevAmount;
  final DateTime prevDate;
  final double newAmount;
  final DateTime newDate;

  /// Düzenlenen ödemenin kimliği. Nakit bacağı benimsenmiş bir satırsa
  /// tutarı ve tarihi değiştirilemez (bankanın satırından gelir).
  final String? paymentId;

  const UpdateDebtPaymentEvent(
    this.debt, {
    required this.prevAmount,
    required this.prevDate,
    required this.newAmount,
    required this.newDate,
    this.paymentId,
  });

  @override
  List<Object?> get props =>
      [debt, prevAmount, prevDate, newAmount, newDate, paymentId];
}

/// Bir ödeme kaydını siler; deftere iade kendi tarihine yazılır.
///
/// [debt] ödeme ÇIKARILMIŞ hâlidir.
class DeleteDebtPaymentEvent extends DebtEvent {
  final DebtEntity debt;
  final double removedAmount;
  final DateTime removedDate;

  /// Silinen ödemenin kimliği. Nakit bacağı benimsenmiş satırsa iade
  /// YAZILMAZ; satır özgün düz hâline döner (bankada para gerçekten çıktı).
  final String? removedPaymentId;

  const DeleteDebtPaymentEvent(
    this.debt, {
    required this.removedAmount,
    required this.removedDate,
    this.removedPaymentId,
  });

  @override
  List<Object?> get props =>
      [debt, removedAmount, removedDate, removedPaymentId];
}

class DeleteDebtEvent extends DebtEvent {
  final String id;
  final String userId;
  final String
      walletId; // Silme işleminden sonra listeyi yenilemek için gerekli

  /// Mutabakat için: anapara eklendiğinde yazılan gelir bu tutardaydı.
  final double principalAmount;

  /// Anaparanın deftere yazıldığı tarih; ters kaydı aynı döneme oturtur.
  final DateTime startDate;

  /// Her ödeme kendi tarihinde tersine çevrilir — toplu tutar yetmez, aksi
  /// hâlde geçmiş ayların gider toplamları bozuk kalırdı.
  final List<Payment> payments;

  /// Anapara eklenirken bakiyeye gelir yazıldı mı (ürün borcunda false);
  /// geri alma hesabı buna göre anaparayı sayar ya da saymaz.
  final bool principalToWallet;

  const DeleteDebtEvent({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.principalAmount,
    required this.startDate,
    this.payments = const [],
    this.principalToWallet = true,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        principalAmount,
        startDate,
        payments,
        principalToWallet,
      ];
}
