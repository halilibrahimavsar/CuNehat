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
  const AddDebtEvent(this.debt);

  @override
  List<Object?> get props => [debt];
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

  const PayDebtEvent(this.debt, this.paymentAmount,
      {required this.paymentDate});

  @override
  List<Object?> get props => [debt, paymentAmount, paymentDate];
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
  List<Object?> get props => [id, walletId];
}
