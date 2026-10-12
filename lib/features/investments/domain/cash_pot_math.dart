import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';

/// Birikim NAKİT KASASI ([InvestmentType.cash]) muhasebesi — saf fonksiyonlar.
///
/// Kasa ile varlık arasındaki para hareketleri CÜZDANA UĞRAMAZ: defterde
/// hareket yazılmaz, cüzdan bakiyesi değişmez; yalnız iki kayıt arasında
/// para yer değiştirir. İnce nokta [InvestmentEntity.bookedCost]: bir kaydın
/// "hatalı giriş" diye silinmesinde cüzdana iade edilen tutar odur. Para
/// kasadan varlığa geçerken deftere işlenmiş maliyet de BİRLİKTE geçer;
/// yoksa kasa silinince varlığa gitmiş paranın da iadesi yazılır (çift
/// iade), varlık silinince hiç yazılmazdı.
///
/// Kasanın `amount == currentValue`'su her zaman bakiyedir; işlenmemiş kısım
/// (`unbookedCost`) = bakiye − işlenmiş kısım.

/// Kasanın bakiyesini [balance], işlenmiş kısmını [booked] yapar.
InvestmentEntity _potWith(InvestmentEntity pot, double balance, double booked) {
  final b = roundToCents(balance);
  final bk = roundToCents(booked.clamp(0, b < 0 ? 0 : b).toDouble());
  return pot.copyWith(
    amount: b,
    currentValue: b,
    unbookedCost: roundToCents(b - bk),
  );
}

/// ANA KASA: [pots] içinde işaretli olan; yoksa `null`.
///
/// Varlık alımında varsayılan kaynak ve satışta varsayılan hedef odur.
/// Cüzdan başına en çok bir tane olur (bkz. `SetPrimaryPotEvent`).
InvestmentEntity? primaryPotOf(Iterable<InvestmentEntity> pots) =>
    pots.where((p) => p.type == InvestmentType.cash && p.isPrimary).firstOrNull;

/// [pots]'u ana kasa BAŞTA olacak biçimde döndürür; geri kalanın sırası
/// (kullanıcının seçtiği sıralama) korunur.
List<InvestmentEntity> primaryPotFirst(List<InvestmentEntity> pots) => [
      for (final p in pots)
        if (p.isPrimary) p,
      for (final p in pots)
        if (!p.isPrimary) p,
    ];

/// Kasanın bakiyesini [newBalance] olarak DÜZELTİR — cüzdana ve deftere
/// dokunmadan ("kasayı düzenle"deki bakiye alanı).
///
/// Para ekle/çek bir AKTARIMDIR (cüzdan ↔ kasa, defterde satır). Düzeltme
/// öyle değil: kasadaki para uygulamanın dışında değişmiştir (elden
/// harcandı, faiz işledi, baştan yanlış girildi) ve kullanıcı yalnız rakamı
/// gerçeğe çekmek ister.
///
/// - Artış işlenmemiş kısma yazılır (o para cüzdandan hiç çıkmadı).
/// - Azalış önce işlenmemiş kısımdan düşer; yetmezse işlenmiş kısım
///   bakiyeyi aşamaz ([_potWith]).
///
/// Çağıran, defter farkı YAZILMAYACAK biçimde gönderir
/// (`UpdateInvestmentEvent.prevAmount == newAmount`).
InvestmentEntity correctPotBalance(InvestmentEntity pot, double newBalance) {
  assert(pot.type == InvestmentType.cash);
  return _potWith(pot, newBalance < 0 ? 0 : newBalance, pot.bookedCost);
}

/// Kasadan [amount] kadar para çıkar (varlık alımı ya da katkı için).
///
/// Dönüş: kasanın yeni hâli + varlığa GEÇEN işlenmiş maliyet. Varlık bu
/// tutarı kendi işlenmiş maliyetine katar; kalanı (varsa) işlenmemiş kısmıdır
/// (ör. kasaya önceki bir satışın KÂRI olarak girmiş para defterde hiç
/// gider olmadı).
({InvestmentEntity pot, double movedBooked}) takeFromPot(
  InvestmentEntity pot,
  double amount,
) {
  assert(pot.type == InvestmentType.cash);
  final moved = roundToCents(amount < pot.bookedCost ? amount : pot.bookedCost);
  return (
    pot: _potWith(pot, pot.amount - amount, pot.bookedCost - moved),
    movedBooked: moved,
  );
}

/// Kasaya [amount] kadar para koy (varlık satışının bedeli). [booked],
/// satılan kısmın işlenmiş maliyetidir: varlıktan kasaya BİRLİKTE geçer.
/// Kâr kasada işlenmemiş kalır; zararlı satışta işlenmiş kısım bakiyeyi
/// aşamaz.
InvestmentEntity putIntoPot(
  InvestmentEntity pot,
  double amount, {
  required double booked,
}) {
  assert(pot.type == InvestmentType.cash);
  return _potWith(pot, pot.amount + amount, pot.bookedCost + booked);
}

/// Kasadan CÜZDANA [amount] çekişinin kasadaki sonucu. İşlenmiş kısım önce
/// düşer (cüzdandan gelen para cüzdana dönüyor); aşan kısım işlenmemişten.
InvestmentEntity withdrawFromPot(InvestmentEntity pot, double amount) =>
    takeFromPot(pot, amount).pot;

/// [asset] için kasadan alınan [cost] tutarlı paranın varlıktaki karşılığı:
/// maliyet [cost] kadar artar, bunun [movedBooked] kadarı işlenmiş sayılır.
/// Yeni kayıtta [asset] maliyeti zaten `cost` olarak kurulmuş gelir
/// ([isNew] = true): yalnız işlenmemiş kısım ayarlanır.
InvestmentEntity bookAssetFromPot(
  InvestmentEntity asset, {
  required double cost,
  required double movedBooked,
  required bool isNew,
}) {
  final unbookedPart = roundToCents(cost - movedBooked);
  return asset.copyWith(
    unbookedCost: roundToCents((isNew ? 0 : asset.unbookedCost) + unbookedPart),
  );
}
