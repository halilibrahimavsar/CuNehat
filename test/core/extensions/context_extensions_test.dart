import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart'
    show CashMovementTags;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestWidget({
    required Locale locale,
    required WidgetBuilder builder,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: Builder(builder: builder),
      ),
    );
  }

  group('LocalizationX', () {
    testWidgets('returns l10n instance', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('en'),
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      );

      final l10n = capturedContext.l10n;
      expect(l10n, isA<AppLocalizations>());
      expect(l10n.language, equals('Language'));
    });

    testWidgets('builds localAuthTexts and sliderTexts correctly in English',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('en'),
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      );

      final authTexts = capturedContext.localAuthTexts;
      expect(authTexts.logoutLabel, equals('Logout'));
      expect(authTexts.welcomeTitle, equals('Welcome'));
      expect(authTexts.msgIncorrectPinRemainingTries, contains('{tries}'));

      final sliderTexts = capturedContext.sliderTexts;
      expect(sliderTexts.savings, equals(capturedContext.l10n.sliderSavings));
      expect(sliderTexts.transactions,
          equals(capturedContext.l10n.sliderTransactions));
      expect(sliderTexts.debt, equals(capturedContext.l10n.sliderDebt));
    });

    testWidgets('translates icon categories in English', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('en'),
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      );

      expect(capturedContext.translateIconCategory('Finans'),
          equals(capturedContext.l10n.categoryFinans));
      expect(capturedContext.translateIconCategory('Grafikler'),
          equals(capturedContext.l10n.categoryGrafikler));
      expect(capturedContext.translateIconCategory('İş & Ofis'),
          equals(capturedContext.l10n.categoryIsVeOfis));
      expect(capturedContext.translateIconCategory('Alışveriş'),
          equals(capturedContext.l10n.categoryAlisveris));
      expect(capturedContext.translateIconCategory('Yemek & İçecek'),
          equals(capturedContext.l10n.categoryYemekVeIcecek));
      expect(capturedContext.translateIconCategory('Ulaşım'),
          equals(capturedContext.l10n.categoryUlasim));
      expect(capturedContext.translateIconCategory('Ev & Yaşam'),
          equals(capturedContext.l10n.categoryEvVeYasam));
      expect(capturedContext.translateIconCategory('Eğlence'),
          equals(capturedContext.l10n.categoryEglence));
      expect(capturedContext.translateIconCategory('Sağlık & Spor'),
          equals(capturedContext.l10n.categorySaglikVeSpor));
      expect(capturedContext.translateIconCategory('Eğitim'),
          equals(capturedContext.l10n.categoryEgitim));
      expect(capturedContext.translateIconCategory('Kişisel Bakım'),
          equals(capturedContext.l10n.categoryKisiselBakim));
      expect(capturedContext.translateIconCategory('Hayvanlar'),
          equals(capturedContext.l10n.categoryHayvanlar));
      expect(capturedContext.translateIconCategory('Seyahat'),
          equals(capturedContext.l10n.categorySeyahat));
      expect(capturedContext.translateIconCategory('Teknoloji'),
          equals(capturedContext.l10n.categoryTeknoloji));
      expect(capturedContext.translateIconCategory('İletişim'),
          equals(capturedContext.l10n.categoryIletisim));
      expect(capturedContext.translateIconCategory('Hediye & Bağış'),
          equals(capturedContext.l10n.categoryHediyeVeBagis));
      expect(capturedContext.translateIconCategory('Hizmetler'),
          equals(capturedContext.l10n.categoryHizmetler));
      expect(capturedContext.translateIconCategory('Diğer'),
          equals(capturedContext.l10n.categoryDiger));
      expect(
          capturedContext.translateIconCategory('Unknown'), equals('Unknown'));
    });

    testWidgets('sistem etiketlerini İngilizce\'ye çevirir', (tester) async {
      // Varsayılan kategori kavramı kalktı: kategori adları artık kullanıcının
      // yazdığı metindir ve çeviriye girmez. Çevrilmesi gereken, otomatik
      // hareketlerin kodda sabit Türkçe duran etiketleridir.
      late BuildContext capturedContext;
      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('en'),
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      );

      expect(capturedContext.translateSystemTag(CashMovementTags.debt),
          equals(capturedContext.l10n.systemTagDebt));
      expect(capturedContext.translateSystemTag(CashMovementTags.debtPayment),
          equals(capturedContext.l10n.systemTagDebtPayment));
      expect(capturedContext.translateSystemTag(CashMovementTags.receivable),
          equals(capturedContext.l10n.systemTagReceivable));
      expect(
          capturedContext
              .translateSystemTag(CashMovementTags.receivableCollection),
          equals(capturedContext.l10n.systemTagReceivableCollection));
      expect(capturedContext.translateSystemTag(CashMovementTags.investmentBuy),
          equals(capturedContext.l10n.systemTagInvestmentBuy));
      expect(
          capturedContext.translateSystemTag(CashMovementTags.investmentSell),
          equals(capturedContext.l10n.systemTagInvestmentSell));
      expect(
          capturedContext
              .translateSystemTag(CashMovementTags.investmentCorrection),
          equals(capturedContext.l10n.systemTagInvestmentCorrection));
      expect(capturedContext.translateSystemTag(CashMovementTags.transfer),
          equals(capturedContext.l10n.systemTagTransfer));

      // Sistem etiketi OLMAYAN her değer (kategori kimliği, silinmiş tag)
      // olduğu gibi döner.
      expect(
          capturedContext.translateSystemTag('018c-uuid'), equals('018c-uuid'));
    });

    testWidgets('TÜM sistem etiketleri çevrilir (eksik case kalmasın)',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('en'),
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      );

      // "isNot(tag)" ile ölçülemez: bazı etiketlerin İngilizcesi aynı kelime
      // ("Transfer"). Ölçüt, çıktının BİLİNEN çeviri kümesinde olmasıdır —
      // switch'e case eklenmemiş bir sabit ham Türkçe döner ve kümeye girmez.
      final l10n = capturedContext.l10n;
      final known = {
        l10n.systemTagDebt,
        l10n.systemTagDebtPayment,
        l10n.systemTagReceivable,
        l10n.systemTagReceivableCollection,
        l10n.systemTagInvestmentBuy,
        l10n.systemTagInvestmentSell,
        l10n.systemTagInvestmentCorrection,
        l10n.systemTagTransfer,
      };

      for (final tag in CashMovementTags.all) {
        expect(known, contains(capturedContext.translateSystemTag(tag)),
            reason: '$tag için switch case yok');
      }
    });
  });
}
