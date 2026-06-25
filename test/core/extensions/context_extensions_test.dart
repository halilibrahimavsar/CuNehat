import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
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

    testWidgets('translates categories in English', (tester) async {
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

      expect(capturedContext.translateCategory('Yemek'),
          equals(capturedContext.l10n.defaultCategoryFood));
      expect(capturedContext.translateCategory('Ulaşım'),
          equals(capturedContext.l10n.defaultCategoryTransport));
      expect(capturedContext.translateCategory('Alışveriş'),
          equals(capturedContext.l10n.defaultCategoryShopping));
      expect(capturedContext.translateCategory('Fatura'),
          equals(capturedContext.l10n.defaultCategoryBills));
      expect(capturedContext.translateCategory('Eğlence'),
          equals(capturedContext.l10n.defaultCategoryEntertainment));
      expect(capturedContext.translateCategory('Maaş'),
          equals(capturedContext.l10n.defaultCategorySalary));
      expect(capturedContext.translateCategory('Yatırım'),
          equals(capturedContext.l10n.defaultCategoryInvestment));
      expect(capturedContext.translateCategory('Serbest'),
          equals(capturedContext.l10n.defaultCategoryFreelance));
      expect(capturedContext.translateCategory('Other'), equals('Other'));
    });
  });
}
