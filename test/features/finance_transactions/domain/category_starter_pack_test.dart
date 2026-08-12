import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/finance_transactions/domain/category_starter_pack.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final expenseNames = <String>[
    for (final g in CategoryStarterPack.expense) ...[
      g.name,
      ...g.children.map((c) => c.name),
    ],
  ];
  final incomeNames = <String>[
    for (final g in CategoryStarterPack.income) ...[
      g.name,
      ...g.children.map((c) => c.name),
    ],
  ];

  group('başlangıç paketi tutarlılığı', () {
    test('kök adları tür içinde tekil', () {
      for (final groups in [
        CategoryStarterPack.expense,
        CategoryStarterPack.income
      ]) {
        final names = groups.map((g) => normalizeCategoryName(g.name)).toList();
        expect(names.toSet().length, names.length);
      }
    });

    test('bir grubun çocuk adları kendi içinde tekil', () {
      for (final g in [
        ...CategoryStarterPack.expense,
        ...CategoryStarterPack.income
      ]) {
        final names =
            g.children.map((c) => normalizeCategoryName(c.name)).toList();
        expect(names.toSet().length, names.length, reason: g.name);
      }
    });

    test('her ikon adı AppIcons kataloğunda gerçekten var', () {
      // getIconData bilinmeyen adı sessizce `account_balance`'a düşürür;
      // yazım hatası ancak böyle yakalanır.
      for (final g in [
        ...CategoryStarterPack.expense,
        ...CategoryStarterPack.income
      ]) {
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
      final fatura =
          CategoryStarterPack.expense.firstWhere((g) => g.name == 'Fatura');
      expect(CategoryStarterPack.sizeOf(fatura), 1 + fatura.children.length);
    });

    test('parentNameOf alt kategoriyi ana kategorisine bağlar', () {
      expect(
          CategoryStarterPack.parentNameOf('Kira', isExpense: true), 'Konut');
      expect(
          CategoryStarterPack.parentNameOf('Fatura', isExpense: true), isNull);
      expect(CategoryStarterPack.parentNameOf('yok', isExpense: true), isNull);
    });

    test('iconNameOf hem kök hem çocuk için çalışır', () {
      expect(
          CategoryStarterPack.iconNameOf('Fatura', isExpense: true), isNotNull);
      expect(CategoryStarterPack.iconNameOf('Elektrik', isExpense: true),
          isNotNull);
    });
  });

  group('CategoryGuesser sözleşmesi', () {
    // Ekstre tahmini kullanıcının kategorilerini ADA göre eşler. Pakette
    // karşılığı olmayan bir grup adı, dokunulmamış bir kurulumda hiçbir zaman
    // tutmaz — bağlantı sessizce kopar.
    test('her gider grubu adı pakette bir kategoriye çözülür', () {
      final available = expenseNames.map(normalizeCategoryName).toSet();

      for (final group in CategoryGuesser.expenseGroupNames) {
        expect(
          available.contains(normalizeCategoryName(group)),
          isTrue,
          reason: '"$group" başlangıç paketinde yok',
        );
      }
    });

    test('her gelir grubu adı pakette bir kategoriye çözülür', () {
      final available = incomeNames.map(normalizeCategoryName).toSet();

      for (final group in CategoryGuesser.incomeGroupNames) {
        expect(
          available.contains(normalizeCategoryName(group)),
          isTrue,
          reason: '"$group" başlangıç paketinde yok',
        );
      }
    });

    test('banka etiketi eşlemesinin hedefleri de pakette var', () {
      final available =
          {...expenseNames, ...incomeNames}.map(normalizeCategoryName).toSet();

      for (final group in CategoryGuesser.tagGroupTargets) {
        expect(
          available.contains(normalizeCategoryName(group)),
          isTrue,
          reason: '"$group" başlangıç paketinde yok',
        );
      }
    });
  });
}
