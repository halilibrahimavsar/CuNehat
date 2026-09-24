import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionFilterCubit', () {
    late TransactionFilterCubit cubit;

    setUp(() => cubit = TransactionFilterCubit());
    tearDown(() => cubit.close());

    test('varsayılan durum: bu ay, karşılaştırma modu, filtresiz', () {
      final month = monthRangeOf(DateTime.now());
      final state = cubit.state;

      expect(state.viewFilter.financeMode, FinanceMode.compare);
      expect(state.viewFilter.startDate, month.start);
      expect(state.viewFilter.endDate, month.end);
      expect(state.dataFilter.selectedCategories, isEmpty);
      expect(state.dataFilter.priceRange, isNull);
      expect(state.dataFilter.searchQuery, isNull);
      expect(cubit.isDefaultPeriod, isTrue);
      expect(cubit.hasAnyActiveFilter, isFalse);
    });

    group('setFinanceMode', () {
      test('mod değişince kategori seçimi temizlenir', () {
        cubit.setCategories({'a', 'b'});
        cubit.setFinanceMode(FinanceMode.expense);

        expect(cubit.state.viewFilter.financeMode, FinanceMode.expense);
        expect(cubit.state.dataFilter.selectedCategories, isEmpty);
      });

      test('tutar aralığı ve arama tür-bağımsızdır, korunur', () {
        cubit.setPriceRange(const PriceRangeFilter(minPrice: 50));
        cubit.setSearchQuery('market');
        cubit.setFinanceMode(FinanceMode.income);

        expect(cubit.state.dataFilter.priceRange,
            const PriceRangeFilter(minPrice: 50));
        expect(cubit.state.dataFilter.searchQuery, 'market');
      });

      test('aynı mod yeniden emit etmez', () {
        final before = cubit.state;
        cubit.setFinanceMode(FinanceMode.compare);
        expect(identical(cubit.state, before), isTrue);
      });
    });

    group('dönem', () {
      test('setPeriod aralığı yazar', () {
        final range = monthRangeOf(DateTime(2026, 3, 1));
        cubit.setPeriod(range);

        expect(cubit.state.viewFilter.startDate, range.start);
        expect(cubit.state.viewFilter.endDate, range.end);
        expect(cubit.isDefaultPeriod, isFalse);
        expect(cubit.hasAnyActiveFilter, isTrue,
            reason: 'varsayılan dışı dönem de bir filtredir');
      });

      test('stepPeriod ay aralığını takvim ayı kadar kaydırır', () {
        cubit.setPeriod(monthRangeOf(DateTime(2026, 3, 15)));
        cubit.stepPeriod(-1);

        expect(cubit.state.viewFilter.startDate, DateTime(2026, 2, 1));
        expect(cubit.state.viewFilter.endDate.day, 28);
      });

      test('aynı gündeki aralık yeniden emit etmez (saat farkı önemsiz)', () {
        final before = cubit.state;
        cubit.setPeriod(DateTimeRange(
          start: DateTime(before.viewFilter.startDate.year,
              before.viewFilter.startDate.month, 1, 6),
          end: before.viewFilter.endDate,
        ));
        expect(identical(cubit.state, before), isTrue);
      });
    });

    group('setSearchQuery', () {
      test('boş ve yalnız boşluk null\'a iner', () {
        cubit.setSearchQuery('market');
        expect(cubit.state.dataFilter.searchQuery, 'market');

        cubit.setSearchQuery('   ');
        expect(cubit.state.dataFilter.searchQuery, isNull);
      });

      test('baştaki/sondaki boşluk kırpılır', () {
        cubit.setSearchQuery('  market  ');
        expect(cubit.state.dataFilter.searchQuery, 'market');
      });
    });

    group('temizleme', () {
      test('clearDataFilters dönemi ve modu KORUR', () {
        cubit.setFinanceMode(FinanceMode.expense);
        cubit.setPeriod(monthRangeOf(DateTime(2026, 3, 1)));
        cubit.setCategories({'a'});
        cubit.setPriceRange(const PriceRangeFilter(maxPrice: 10));
        cubit.setSearchQuery('x');

        cubit.clearDataFilters();

        expect(cubit.state.dataFilter.hasActiveFilters, isFalse);
        expect(cubit.state.viewFilter.financeMode, FinanceMode.expense);
        expect(cubit.state.viewFilter.startDate, DateTime(2026, 3, 1));
      });

      test('clearAll dönemi de sıfırlar ama modu korur', () {
        cubit.setFinanceMode(FinanceMode.income);
        cubit.setPeriod(monthRangeOf(DateTime(2026, 3, 1)));
        cubit.setCategories({'a'});

        cubit.clearAll();

        expect(cubit.isDefaultPeriod, isTrue);
        expect(cubit.state.dataFilter.hasActiveFilters, isFalse);
        expect(cubit.state.viewFilter.financeMode, FinanceMode.income,
            reason: 'temizleme kullanıcının bakış açısını sıfırlamamalı');
      });
    });

    test('setCategories boş küme filtreyi kaldırır', () {
      cubit.setCategories({'a'});
      cubit.setCategories(const {});
      expect(cubit.state.dataFilter.selectedCategories, isEmpty);
      expect(cubit.state.dataFilter.hasActiveFilters, isFalse);
    });

    test('setPriceRange boş aralığı null sayar', () {
      cubit.setPriceRange(const PriceRangeFilter());
      expect(cubit.state.dataFilter.priceRange, isNull);
    });

    test('updateFilter tüm durumu değiştirir', () {
      final next = CombinedFilter(
        viewFilter: ViewFilter(
          financeMode: FinanceMode.expense,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
        ),
        dataFilter: const DataFilter(selectedCategories: {'Food'}),
      );
      cubit.updateFilter(next);
      expect(cubit.state, next);
    });
  });

  // Kart bağlamında dönem EKSTRE dönemidir: kart kullanıcısı takvim ayıyla
  // değil ekstreyle düşünür (kesim 15 → dönem 16 … 15).
  group('ekstre dönemi (kart bağlamı)', () {
    const card = CreditCardInfo(closingDay: 15, dueDay: 25);

    test('karta geçince varsayılan dönem içinde bulunulan ekstre olur', () {
      final cubit = TransactionFilterCubit();
      cubit.useStatementCycle(card);
      final expected = CardCycle(card).periodContaining(DateTime.now());
      expect(dayOf(cubit.period.start), expected.start);
      expect(dayOf(cubit.period.end), expected.end);
      expect(cubit.isStatementPeriod, isTrue);
      expect(cubit.isDefaultPeriod, isTrue);
      expect(cubit.hasAnyActiveFilter, isFalse);
    });

    test('ok bir EKSTRE atlar (ay uzunluğu değil)', () {
      final cubit = TransactionFilterCubit()..useStatementCycle(card);
      cubit.setPeriod(DateTimeRange(
          start: DateTime(2026, 1, 16), end: DateTime(2026, 2, 15)));
      cubit.stepPeriod(1);
      expect(dayOf(cubit.period.start), DateTime(2026, 2, 16));
      expect(dayOf(cubit.period.end), DateTime(2026, 3, 15));
      cubit.stepPeriod(-2);
      expect(dayOf(cubit.period.start), DateTime(2025, 12, 16));
      expect(dayOf(cubit.period.end), DateTime(2026, 1, 15));
    });

    test('kesim 31: Şubat ekstresi ayın son gününde kesilir', () {
      final cubit = TransactionFilterCubit()
        ..useStatementCycle(const CreditCardInfo(closingDay: 31, dueDay: 10));
      cubit.setPeriod(DateTimeRange(
          start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)));
      expect(cubit.isStatementPeriod, isTrue);
      cubit.stepPeriod(1);
      expect(dayOf(cubit.period.start), DateTime(2026, 2, 1));
      expect(dayOf(cubit.period.end), DateTime(2026, 2, 28));
      cubit.stepPeriod(1);
      expect(dayOf(cubit.period.start), DateTime(2026, 3, 1));
      expect(dayOf(cubit.period.end), DateTime(2026, 3, 31));
    });

    test('hesaba dönünce ekstre dönemi AYA döner', () {
      final cubit = TransactionFilterCubit()..useStatementCycle(card);
      cubit.useStatementCycle(null);
      final month = monthRangeOf(DateTime.now());
      expect(dayOf(cubit.period.start), dayOf(month.start));
      expect(cubit.isStatementPeriod, isFalse);
    });

    test('kullanıcının seçtiği özel aralığa bağlam değişimi DOKUNMAZ', () {
      final cubit = TransactionFilterCubit();
      final custom = DateTimeRange(
          start: DateTime(2025, 3, 3), end: DateTime(2025, 3, 9, 23, 59, 59));
      cubit.setPeriod(custom);
      cubit.useStatementCycle(card);
      expect(dayOf(cubit.period.start), DateTime(2025, 3, 3));
      cubit.useStatementCycle(null);
      expect(dayOf(cubit.period.start), DateTime(2025, 3, 3));
    });

    test('ekstre dışı aralıkta ok eski kuralla kayar', () {
      final cubit = TransactionFilterCubit()..useStatementCycle(card);
      cubit.setPeriod(monthRangeOf(DateTime(2026, 4, 1)));
      cubit.stepPeriod(1);
      expect(dayOf(cubit.period.start), DateTime(2026, 5, 1));
    });

    test('"temizle" kart bağlamında içinde bulunulan ekstreye döner', () {
      final cubit = TransactionFilterCubit()..useStatementCycle(card);
      cubit.stepPeriod(-3);
      cubit.clearAll();
      expect(cubit.isDefaultPeriod, isTrue);
      expect(cubit.isStatementPeriod, isTrue);
    });
  });
}
