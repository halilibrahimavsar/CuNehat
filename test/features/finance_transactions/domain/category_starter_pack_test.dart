import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/l10n/category_seed_names.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/finance_transactions/domain/category_starter_pack.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final languages =
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();

  final allGroups = [
    ...CategoryStarterPack.expense,
    ...CategoryStarterPack.income,
  ];

  group('başlangıç paketi tutarlılığı', () {
    test('anahtarlar paket genelinde tekil', () {
      // Anahtar artık KİMLİK: iki kayıt aynı anahtarı taşırsa sözlük hedefi
      // hangisini kastettiğini söyleyemez.
      final keys = CategoryStarterPack.allKeys.toList();
      expect(keys.toSet().length, keys.length);
    });

    test('alt kategori anahtarı ana kategorisinin YOLUNU taşır', () {
      // `resolveTarget` üst kategoriyi anahtar yolundan okuyor; kayan bir
      // ön ek, alt kategoriyi yanlış kökün altına düşürür.
      for (final g in allGroups) {
        for (final c in g.children) {
          expect(c.key, startsWith('${g.key}$kCategoryKeySeparator'),
              reason: '${c.key}, ${g.key} altında değil');
        }
      }
    });

    test('her anahtarın DESTEKLENEN HER DİLDE bir çevirisi var', () {
      // Çeviri unutulursa `categorySeedName` anahtarın kendisini döner; o ad
      // kullanıcının kategori listesine `bills.electricity` diye yazılırdı.
      for (final key in CategoryStarterPack.allKeys) {
        for (final language in languages) {
          expect(categorySeedName(key, language), isNot(key),
              reason: '$key için $language çevirisi yok');
        }
      }
    });

    test('kök adları HER DİLDE tür içinde tekil', () {
      // Tekillik yalnız Türkçede sağlanırsa İngilizce kurulum iki "Other"
      // üretir ve `taken` ikincisini sessizce yutar.
      for (final groups in [
        CategoryStarterPack.expense,
        CategoryStarterPack.income
      ]) {
        for (final language in languages) {
          final names = groups
              .map((g) => categorySeedName(g.key, language))
              .map(normalizeCategoryName)
              .toList();
          expect(names.toSet().length, names.length, reason: language);
        }
      }
    });

    test('bir grubun çocuk adları HER DİLDE kendi içinde tekil', () {
      for (final g in allGroups) {
        for (final language in languages) {
          final names = g.children
              .map((c) => categorySeedName(c.key, language))
              .map(normalizeCategoryName)
              .toList();
          expect(names.toSet().length, names.length,
              reason: '${g.key} / $language');
        }
      }
    });

    test('her ikon adı AppIcons kataloğunda gerçekten var', () {
      // getIconData bilinmeyen adı sessizce `account_balance`'a düşürür;
      // yazım hatası ancak böyle yakalanır.
      for (final g in allGroups) {
        for (final name in [g.iconName, ...g.children.map((c) => c.iconName)]) {
          expect(
            AppIcons.getIconData(name),
            isNot(Icons.account_balance),
            reason: '$name AppIcons içinde yok',
          );
        }
      }
    });

    test('sizeOf kendisi + çocuklarını sayar', () {
      final bills =
          CategoryStarterPack.expense.firstWhere((g) => g.key == 'bills');
      expect(CategoryStarterPack.sizeOf(bills), 1 + bills.children.length);
    });

    test('iconNameOf hem kök hem çocuk için çalışır', () {
      expect(CategoryStarterPack.iconNameOf('bills', isExpense: true),
          'receipt_long');
      expect(
        CategoryStarterPack.iconNameOf('bills.electricity', isExpense: true),
        'lightbulb',
      );
      expect(CategoryStarterPack.iconNameOf('yok', isExpense: true), isNull);
      // Anahtarlar tür içinde aranır: gider anahtarı gelir tarafında yok.
      expect(CategoryStarterPack.iconNameOf('bills', isExpense: false), isNull);
    });
  });

  group('CategoryGuesser sözleşmesi', () {
    // Ekstre tahmini kullanıcının kategorilerini ADA göre eşler, ama sözlük
    // ANAHTAR hedefler. Pakette karşılığı olmayan bir anahtar, dokunulmamış
    // bir kurulumda hiçbir zaman tutmaz — bağlantı sessizce kopar.
    void expectResolvable(
      Iterable<CategoryTarget> targets,
      List<StarterPackGroup> pack,
    ) {
      final roots = {for (final g in pack) g.key: g};
      for (final target in targets) {
        final parentKey = target.parentKey;
        if (parentKey == null) {
          expect(roots.containsKey(target.key), isTrue,
              reason: '"${target.key}" pakette kök olarak yok');
          continue;
        }
        // Alt kategori hedefi: ana kategori pakette VAR olmalı (son çare
        // düşüşü oraya) ve alt kategori gerçekten onun ALTINDA durmalı.
        final root = roots[parentKey];
        expect(root, isNotNull, reason: '"$parentKey" pakette kök olarak yok');
        expect(
          root!.children.any((c) => c.key == target.key),
          isTrue,
          reason: '"${target.key}", "$parentKey" altında yok',
        );
      }
    }

    test('her gider hedefi pakette bir kategoriye çözülür', () {
      expectResolvable(
          CategoryGuesser.expenseTargets, CategoryStarterPack.expense);
    });

    test('her gelir hedefi pakette bir kategoriye çözülür', () {
      expectResolvable(
          CategoryGuesser.incomeTargets, CategoryStarterPack.income);
    });

    test('aynı anahtar kelime iki hedefte birden geçmez', () {
      // Sözlükte en UZUN anahtar kazanıyor; aynı kelimeyi iki hedefe birden
      // yazmak, kazananı harita sırasına bağlayan görünmez bir sözleşme kurar.
      for (final targets in [
        CategoryGuesser.expenseKeywords,
        CategoryGuesser.incomeKeywords,
      ]) {
        final seen = <String, String>{};
        targets.forEach((path, keywords) {
          for (final keyword in keywords) {
            expect(seen[keyword], isNull,
                reason: '"$keyword" hem ${seen[keyword]} hem $path içinde');
            seen[keyword] = path;
          }
        });
      }
    });
  });
}
