/// Başlangıç paketindeki kategori adlarının **anahtar → çeviri** köprüsü.
///
/// Kategori adı kullanıcı verisidir: kurulduğu anda Hive'a YAZILIR ve orada
/// donar. Bu yüzden çeviri iki ayrı soruya cevap vermek zorunda:
///
/// 1. *"Bu kategoriyi şimdi kursam ne yazacağım?"* → [categorySeedName],
///    seçili dil.
/// 2. *"Kullanıcının listesindeki şu kayıt benim `bills.electricity`
///    hedefim mi?"* → [categorySeedNameCandidates], **tüm** diller. Türkçe
///    kurup İngilizceye geçen kullanıcının kategorisi hâlâ "Elektrik"tir;
///    yalnız bugünkü dile bakan bir eşleşme sessizce hiçbir şey bulamaz ve
///    banka ekstresi tahmini tamamen ölür.
///
/// Adlar ARB'de durur (projenin l10n konvansiyonu), anahtarlar burada:
/// `CategoryStarterPack` ile `CategoryGuesser` arasındaki sözleşme artık
/// Türkçe ad değil bu ASCII anahtardır — bir çeviriyi değiştirmek
/// eşleşmeyi koparmaz. Bağ `category_starter_pack_test.dart` ile kilitli.
///
/// Widget ağacı GEREKMEZ (`lookupAppLocalizations`, bkz. aynı kalıp
/// `NotificationLocalizer`): kategori kuran yollar (başlangıç paketi,
/// ekstre önerisi) bloc/servis katmanındadır.
library;

import 'package:flutter/widgets.dart';

import 'package:cunehat/core/l10n/app_localizations.dart';

/// [key]'in [languageCode] dilindeki adı. Dil desteklenmiyorsa Türkçeye
/// düşer — `MaterialApp`'in kendi locale çözümüyle aynı davranış.
String categorySeedName(String key, String languageCode) =>
    _nameOf(key, _localizationsFor(languageCode));

/// [key]'in DESTEKLENEN TÜM dillerdeki adları (tekilleştirilmiş).
///
/// Kullanıcının kategorisi hangi dilde kurulduysa o adı taşır; hedefi
/// çözerken hepsi denenir. Sonuç önbelleklenir: `resolveTarget` ekstredeki
/// her satır için çağrılıyor, her seferinde 2 `AppLocalizations` kurmak
/// sıcak döngüde bedava değil.
List<String> categorySeedNameCandidates(String key) =>
    _candidateCache[key] ??= <String>{
      for (final l10n in _allLocalizations) _nameOf(key, l10n),
    }.toList(growable: false);

final _candidateCache = <String, List<String>>{};

final List<AppLocalizations> _allLocalizations = [
  for (final locale in AppLocalizations.supportedLocales)
    lookupAppLocalizations(locale),
];

AppLocalizations _localizationsFor(String languageCode) {
  final supported = AppLocalizations.supportedLocales
      .any((locale) => locale.languageCode == languageCode);
  return lookupAppLocalizations(
    supported ? Locale(languageCode) : const Locale('tr'),
  );
}

/// Bilinmeyen anahtar anahtarın KENDİSİNİ döner: çeviri unutulmuş bir kategori
/// yüzünden kurulum patlamasın. Böyle bir anahtarın hiç olmadığı
/// `category_starter_pack_test.dart` içinde ayrıca doğrulanır.
String _nameOf(String key, AppLocalizations l10n) => switch (key) {
      'groceries' => l10n.catSeedGroceries,
      'groceries.produce' => l10n.catSeedGroceriesProduce,
      'groceries.butcher' => l10n.catSeedGroceriesButcher,
      'groceries.drinks' => l10n.catSeedGroceriesDrinks,
      'dining' => l10n.catSeedDining,
      'dining.restaurant' => l10n.catSeedDiningRestaurant,
      'dining.cafe' => l10n.catSeedDiningCafe,
      'dining.takeaway' => l10n.catSeedDiningTakeaway,
      'transport' => l10n.catSeedTransport,
      'transport.fuel' => l10n.catSeedTransportFuel,
      'transport.public' => l10n.catSeedTransportPublic,
      'transport.taxi' => l10n.catSeedTransportTaxi,
      'transport.parking' => l10n.catSeedTransportParking,
      'bills' => l10n.catSeedBills,
      'bills.electricity' => l10n.catSeedBillsElectricity,
      'bills.water' => l10n.catSeedBillsWater,
      'bills.gas' => l10n.catSeedBillsGas,
      'bills.internet' => l10n.catSeedBillsInternet,
      'bills.phone' => l10n.catSeedBillsPhone,
      'housing' => l10n.catSeedHousing,
      'housing.rent' => l10n.catSeedHousingRent,
      'housing.dues' => l10n.catSeedHousingDues,
      'housing.maintenance' => l10n.catSeedHousingMaintenance,
      'shopping' => l10n.catSeedShopping,
      'shopping.clothing' => l10n.catSeedShoppingClothing,
      'shopping.electronics' => l10n.catSeedShoppingElectronics,
      'shopping.homegoods' => l10n.catSeedShoppingHomeGoods,
      'health' => l10n.catSeedHealth,
      'health.pharmacy' => l10n.catSeedHealthPharmacy,
      'health.doctor' => l10n.catSeedHealthDoctor,
      'health.fitness' => l10n.catSeedHealthFitness,
      'education' => l10n.catSeedEducation,
      'education.school' => l10n.catSeedEducationSchool,
      'education.books' => l10n.catSeedEducationBooks,
      'entertainment' => l10n.catSeedEntertainment,
      'entertainment.cinema' => l10n.catSeedEntertainmentCinema,
      'entertainment.subscriptions' => l10n.catSeedEntertainmentSubscriptions,
      'entertainment.games' => l10n.catSeedEntertainmentGames,
      'personal' => l10n.catSeedPersonal,
      'personal.hairdresser' => l10n.catSeedPersonalHairdresser,
      'personal.cosmetics' => l10n.catSeedPersonalCosmetics,
      'investment' => l10n.catSeedInvestment,
      'other' => l10n.catSeedOther,
      'salary' => l10n.catSeedSalary,
      'sideIncome' => l10n.catSeedSideIncome,
      'sideIncome.bonus' => l10n.catSeedSideIncomeBonus,
      'sideIncome.freelance' => l10n.catSeedSideIncomeFreelance,
      'rentalIncome' => l10n.catSeedRentalIncome,
      'investmentIncome' => l10n.catSeedInvestmentIncome,
      'otherIncome' => l10n.catSeedOtherIncome,
      _ => key,
    };
