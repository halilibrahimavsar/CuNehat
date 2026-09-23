import 'package:equatable/equatable.dart';

import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

/// Bir kaydın (yatırım alımı, katkı, borç ödemesi, anapara…) nakit bacağı
/// deftere NEREDEN gelir.
///
/// Eskiden tek yol vardı: kuplaj kendi hareketini yazar. Oysa ekstreden
/// içe aktarılmış satır çoğu zaman defterde ZATEN duruyor ("MIDAS MENKUL
/// DEGERLER −5.000", "KREDI TAKSIT −2.500"); kullanıcı aynı alımı/ödemeyi
/// modülüne de girince kuplaj ikinci bir hareket yazıyor ve para iki kez
/// düşüyordu.
sealed class CashSource extends Equatable {
  const CashSource();

  @override
  List<Object?> get props => const [];
}

/// Kuplaj yeni bir hareket yazar (her zamanki davranış).
final class NewCashMovement extends CashSource {
  const NewCashMovement();
}

/// Defterde zaten duran düz satır bu kaydın nakit bacağı olur; YENİ hareket
/// yazılmaz (bkz. `WalletMetricsService.adoptCashMovement`). Satırın tutarı
/// ve tarihi kaydın tutarı ve tarihi sayılır.
final class AdoptedCashMovement extends CashSource {
  final TransactionEntity transaction;
  const AdoptedCashMovement(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Deftere hiç yazılmaz: varlık uygulamadan ÖNCE alınmıştı ("bu varlık zaten
/// bende"); maliyeti cüzdandan çıkmadı.
final class OffLedgerCash extends CashSource {
  const OffLedgerCash();
}
