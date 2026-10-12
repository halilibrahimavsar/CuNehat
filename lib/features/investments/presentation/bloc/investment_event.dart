part of 'investment_bloc.dart';

sealed class InvestmentEvent extends Equatable {
  const InvestmentEvent();

  @override
  List<Object> get props => [];
}

final class GetInvestmentsEvent extends InvestmentEvent {
  final String userId;
  final String walletId;

  const GetInvestmentsEvent({
    required this.userId,
    required this.walletId,
  });
  @override
  List<Object> get props => [userId, walletId];
}

/// Hedef ekleme/güncelleme (aynı yol: kimlik çağıranda üretilir).
final class SaveGoalEvent extends InvestmentEvent {
  final GoalEntity goal;

  const SaveGoalEvent(this.goal);

  @override
  List<Object> get props => [goal];
}

/// Hedefi siler; ÜYELERİ SİLMEZ, bağlarını koparır (bkz. [DeleteGoalUseCase]).
final class DeleteGoalEvent extends InvestmentEvent {
  final GoalEntity goal;

  const DeleteGoalEvent(this.goal);

  @override
  List<Object> get props => [goal];
}

final class CreateInvestmentEvent extends InvestmentEvent {
  final String userId;
  final String walletId;
  final InvestmentEntity investment;

  /// Alımın nakit bacağı nereden gelir: yeni gider (varsayılan), defterde
  /// ZATEN duran satır (ekstreden gelen alım — benimsenir, ikinci gider
  /// yazılmaz) ya da hiç ("zaten bende"; kaydın `unbookedCost`'u bunu taşır).
  final CashSource cashSource;

  const CreateInvestmentEvent({
    required this.investment,
    required this.userId,
    required this.walletId,
    this.cashSource = const NewCashMovement(),
  });
  @override
  List<Object> get props => [investment, userId, walletId, cashSource];
}

final class UpdateInvestmentEvent extends InvestmentEvent {
  final String userId;
  final String walletId;
  final InvestmentEntity investment;

  /// Nakit mutabakatı bu ikisinin FARKINDAN türer ve ikisi de kaydın
  /// deftere İŞLENMİŞ maliyetidir (`InvestmentEntity.bookedCost`), ham
  /// `amount` değil: "zaten bende" denen kısım cüzdandan hiç çıkmadığı için
  /// değişimi de cüzdana yazılmaz.
  final double prevAmount;
  final double newAmount;

  /// Maliyet farkının deftere yazılacağı TARİH. Varsayılanı YOKTUR: çağıran
  /// ne demek istediğini söylemek zorundadır.
  ///
  /// İki çağıran iki farklı şey demek istiyor ve bloc bunu tarihten
  /// türetemez:
  ///  * **Katkı** (ContributeSheet) — para BUGÜN çıkıyor → `DateTime.now()`.
  ///  * **Düzenleme** (edit sheet) — kaydın özgün maliyeti düzeltiliyor,
  ///    yeni bir para hareketi YOK → `investment.dateAdded`.
  ///
  /// Alan yokken her ikisi de "şimdi"ye yazılıyordu. Ocak'ta açılıp Temmuz'da
  /// maliyeti düzeltilen bir kayıtta düzeltme Temmuz'a düşüyor, silme
  /// düzeltmesi ise kümülatif maliyeti Ocak'a ters çeviriyordu: bakiye
  /// doğru çıkıyor ama Ocak'a hayali gelir, Temmuz'a tersi alınmamış gider
  /// kalıyordu.
  final DateTime bookingDate;

  /// Maliyet artışının (katkının) nakit bacağı: yeni gider (varsayılan) ya da
  /// defterde zaten duran satır (bkz. [CreateInvestmentEvent.cashSource]).
  final CashSource cashSource;

  const UpdateInvestmentEvent({
    required this.investment,
    required this.userId,
    required this.walletId,
    required this.prevAmount,
    required this.newAmount,
    required this.bookingDate,
    this.cashSource = const NewCashMovement(),
  });
  @override
  List<Object> get props =>
      [investment, userId, walletId, bookingDate, cashSource];
}

/// Bir nakit kasasını ANA KASA yapar ([primary] true) ya da işaretini
/// kaldırır. Cüzdanın öteki kasalarındaki işaret düşürülür: en çok bir ana
/// kasa olur. Para hareketi YOKTUR — defter ve cüzdan değişmez.
final class SetPrimaryPotEvent extends InvestmentEvent {
  final InvestmentEntity pot;
  final bool primary;

  const SetPrimaryPotEvent({required this.pot, required this.primary});

  @override
  List<Object> get props => [pot, primary];
}

/// Canlı fiyatlardan güncel değer yenileme. [investmentId] verilirse tek
/// kayıt, verilmezse yenilenebilir (sembol + miktar) tüm kayıtlar güncellenir.
/// Maliyet değişmediği için defterde nakit hareketi oluşturmaz.
final class RefreshPricesEvent extends InvestmentEvent {
  final String userId;
  final String walletId;
  final String? investmentId;

  /// Değerlemenin yapılacağı birim — cüzdanın kendi birimi. Fiyat kaynağı
  /// başka bir birimdeyse çapraz kurla buraya çevrilir.
  final String walletCurrency;

  const RefreshPricesEvent({
    required this.userId,
    required this.walletId,
    required this.walletCurrency,
    this.investmentId,
  });
  @override
  List<Object> get props =>
      [userId, walletId, walletCurrency, investmentId ?? ''];
}

/// Kısmi satış: kaydın bir bölümü elden çıkar, kayıt silinmez.
///
/// Nakit kuplajı maliyet farkından TÜRETİLEMEZ (bkz. [UpdateInvestmentEvent]):
/// satışta cüzdana giren, maliyetin düşen kısmı değil kullanıcının eline
/// geçen [proceeds]'tir. Bu yüzden ayrı bir olay.
final class PartialSellInvestmentEvent extends InvestmentEvent {
  final String userId;
  final String walletId;

  /// Satıştan ÖNCEKİ hâli; geri alma bunu aynı kimlikle geri yazar.
  final InvestmentEntity previous;

  /// Satıştan sonra kalan kayıt (miktar/maliyet/değer düşülmüş).
  final InvestmentEntity remaining;

  /// Satışın elde ettiği tutar: cüzdana gelir ya da [targetPot]'a girer.
  final double proceeds;

  /// Verilirse bedel bu NAKİT KASASINA girer, cüzdana gelir yazılmaz.
  final InvestmentEntity? targetPot;

  const PartialSellInvestmentEvent({
    required this.previous,
    required this.remaining,
    required this.proceeds,
    required this.userId,
    required this.walletId,
    this.targetPot,
  });

  @override
  List<Object> get props => [
        previous,
        remaining,
        proceeds,
        userId,
        walletId,
        if (targetPot != null) targetPot!,
      ];
}

final class DeleteInvestmentEvent extends InvestmentEvent {
  final String userId;
  final String walletId;
  final String id;

  /// Silme düzeltmesinde iade edilecek tutar: kaydın deftere İŞLENMİŞ
  /// maliyeti (`InvestmentEntity.bookedCost`), ham `amount` değil.
  final double amount;

  /// Satışta nakit gelire dönüşen tutar — kaydın `currentValue` alanı değil,
  /// satış sayfasında onaylanan tutar (kayıttaki değer bayat olabilir).
  final double currentValue;

  /// true → satış: güncel değer kadar nakit gelir oluşturulur.
  /// false → hatalı giriş düzeltme: kayıt silinir ve eklemede yazılan alım
  /// gideri, maliyet (amount) kadar gelirle ters kayıt edilir.
  final bool recordSale;

  /// Yatırımın deftere yazıldığı tarih. DÜZELTME ters kaydı buraya yazılır
  /// (satış ters kayıt değil, bugün gerçekleşen bir olaydır).
  final DateTime dateAdded;

  /// Satışta verilirse bedel bu NAKİT KASASINA girer, cüzdana gelir
  /// yazılmaz.
  final InvestmentEntity? targetPot;

  const DeleteInvestmentEvent({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.amount,
    required this.currentValue,
    required this.dateAdded,
    this.recordSale = true,
    this.targetPot,
  });
  @override
  List<Object> get props => [
        id,
        userId,
        walletId,
        recordSale,
        if (targetPot != null) targetPot!,
      ];
}
