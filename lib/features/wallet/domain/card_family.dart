/// Kart ↔ cüzdan aile ilişkisi — saf fonksiyonlar, I/O yok.
///
/// **Model:** kredi kartı veride ayrı bir cüzdandır (kendi defteri, eksi
/// bakiyesi; bkz. `CreditCardInfo`), ama kullanıcı için bir cüzdanın
/// İÇİNDEDİR: "Maaş Hesabı"nın Bonus kartı. Bağ
/// [CreditCardInfo.paymentWalletId]'dir — kartın ödendiği cüzdan aynı
/// zamanda sahibidir (şema değişmedi, alanın anlamı genişledi).
///
/// Arayüz kartı hiçbir yerde "ayrı cüzdan" gibi listelemez: cüzdan
/// listesinde sahibinin altında durur, işlemler ekranında sahibinin
/// bağlamından bir sekmedir. Birikim ve borç ekranları kartın değil
/// SAHİBİNİN verisini gösterir ([accountOf]) — kartın yatırımı/borç
/// kaydı olmaz.
///
/// **Yetim kart:** sahibi yoksa (kurulumda seçilmedi, sahibi silindi ya da
/// sahibi de bir kart) kart kendi başına üst düzeydedir; arayüz onu bir
/// cüzdana bağlamayı önerir. Veri kaybı yok, yalnız gösterim farkı.
library;

import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';

/// Kartın sahibi olan (kart olmayan) cüzdan; yetim kartta ve düz cüzdanda
/// `null`.
WalletEntity? cardOwner(WalletEntity wallet, Iterable<WalletEntity> all) {
  final ownerId = wallet.creditCard?.paymentWalletId;
  if (ownerId == null || ownerId == wallet.id) return null;
  for (final w in all) {
    if (w.id == ownerId) return w.isCreditCard ? null : w;
  }
  return null;
}

/// [walletId]'ye bağlı kartlar, verilen sırayla (cüzdan sırası).
List<WalletEntity> cardsOf(String? walletId, Iterable<WalletEntity> all) {
  if (walletId == null) return const [];
  return [
    for (final w in all)
      if (w.isCreditCard &&
          w.id != walletId &&
          w.creditCard!.paymentWalletId == walletId &&
          cardOwner(w, all) != null)
        w,
  ];
}

/// Birikim/borç/kategori gibi "hesap" verisinin sahibi: bağlı kartta
/// sahibi, diğer her durumda cüzdanın kendisi.
WalletEntity accountOf(WalletEntity wallet, Iterable<WalletEntity> all) =>
    cardOwner(wallet, all) ?? wallet;

/// Cüzdan listesinin üst düzeyi: düz cüzdanlar + yetim kartlar. Bağlı
/// kartlar sahiplerinin altında gösterilir.
List<WalletEntity> topLevelWallets(Iterable<WalletEntity> all) => [
      for (final w in all)
        if (!w.isCreditCard || cardOwner(w, all) == null) w,
    ];

/// Bağlı kart mı (sahibi var)?
bool isAttachedCard(WalletEntity wallet, Iterable<WalletEntity> all) =>
    cardOwner(wallet, all) != null;

/// Cüzdanlar AİLE sırasında: her üst düzey cüzdanın hemen ardından kartları.
/// Hedef seçicilerinde (ekstre içe aktarımı) kart sahibinin altında görünsün.
List<WalletEntity> walletsInFamilyOrder(Iterable<WalletEntity> all) => [
      for (final w in topLevelWallets(all)) ...[
        w,
        ...cardsOf(w.id, all),
      ],
    ];

/// Seçicilerdeki ad: bağlı kartta "Maaş Hesabı › Bonus", diğerlerinde ad.
String familyLabel(WalletEntity wallet, Iterable<WalletEntity> all) {
  final owner = cardOwner(wallet, all);
  return owner == null ? wallet.name : '${owner.name} › ${wallet.name}';
}
