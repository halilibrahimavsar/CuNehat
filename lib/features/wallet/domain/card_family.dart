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

import 'package:cunehat/core/utils/money_math.dart';
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

/// Bir hesabın BÜTÜN borcu, kaynağına göre: borç modülündeki kayıtlar
/// ([WalletEntity.debt] — kredi, kişisel borç) + bağlı kartların bugünkü
/// borcu (kart cüzdanının eksi bakiyesi; gelecek tarihli taksitler dahil,
/// bankanın "güncel borç"u gibi).
///
/// **Neden:** borç iki yerde tutuluyor ve birbirinden habersizdi. Bonus
/// kartında 1.200 ₺ borcu olan kullanıcı Borç sekmesinde, çekmecede ve
/// cüzdan kartında "Borç 0,00 ₺" görüyordu; üçü de yalnız modülü sayıyordu.
///
/// [wallet] bağlı bir kartsa sahibinin ailesi hesaplanır (Borç sekmesi
/// kartın değil sahibinin verisidir). Yetim kart kendi borcunu taşır.
/// Sahibinden farklı birimdeki kartlar toplanmaz: tutar tek birimde yazılır.
({double loans, double cards, double total}) debtOverview(
  WalletEntity wallet,
  Iterable<WalletEntity> all,
) {
  final account = accountOf(wallet, all);
  final family = account.isCreditCard ? [account] : cardsOf(account.id, all);
  var cards = 0.0;
  for (final c in family) {
    if (c.currency == account.currency && c.balance < 0) cards -= c.balance;
  }
  final loans = account.isCreditCard ? 0.0 : account.debt;
  final roundedCards = roundToCents(cards);
  return (
    loans: loans,
    cards: roundedCards,
    total: roundToCents(loans + roundedCards),
  );
}

/// TL cinsinden NET değer kırılımı: hesaplar − kart borçları − kalan
/// kredi/kişisel borçlar + alacaklar. Birikim (yatırım) ayrı tutulur.
///
/// **Neden borç modülü de düşülüyor:** kredinin ana parası hesaba GELİR
/// olarak girer; net yalnız kart borcunu düşerken kredisi olan kullanıcının
/// neti, çektiği kredi kadar şişik görünüyordu.
///
/// Düşülecek ya da eklenecek hiçbir şey yoksa (kart, borç, alacak yok)
/// `null`: kırılım hesap toplamını tekrar etmekten ibaret olurdu. Bir kur
/// eksikse de `null` — yanıltıcı eksik toplam göstermeyiz. TL için kur
/// sorulmaz.
({
  double net,
  double accounts,
  double cardDebt,
  double loans,
  double receivables,
})? netBreakdown(
  Iterable<WalletEntity> wallets, {
  required double? Function(String currency) rateToTry,
}) {
  final relevant = wallets.any((w) =>
      w.isCreditCard || moneyIsPositive(w.debt) || moneyIsPositive(w.credit));
  if (!relevant) return null;
  var accounts = 0.0;
  var cardDebt = 0.0;
  var loans = 0.0;
  var receivables = 0.0;
  for (final w in wallets) {
    final rate = w.currency == 'TRY' ? 1.0 : rateToTry(w.currency);
    if (rate == null) return null;
    if (w.isCreditCard) {
      cardDebt += -w.balance * rate;
    } else {
      accounts += w.balance * rate;
    }
    loans += w.debt * rate;
    receivables += w.credit * rate;
  }
  return (
    net: roundToCents(accounts - cardDebt - loans + receivables),
    accounts: roundToCents(accounts),
    cardDebt: roundToCents(cardDebt),
    loans: roundToCents(loans),
    receivables: roundToCents(receivables),
  );
}
