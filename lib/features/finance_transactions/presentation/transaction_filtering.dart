/// İşlem listesine filtre uygulamanın TEK yeri.
///
/// Eskiden sayfanın içinde özel bir metottu ve üç sorun doğuruyordu:
/// `DataFilter.searchQuery` hiç uygulanmıyordu (alan vardı, etkisi yoktu),
/// mantık widget'a gömülü olduğu için test edilemiyordu, ve her build'de
/// defter (sıralama + running balance) baştan kuruluyordu.
///
/// Bu yüzden iki adıma ayrıldı:
/// 1. [buildLedger] — PAHALI kısım (tam geçmişi sırala + bakiye zinciri).
///    Yalnız defter değiştiğinde çalışmalı, çağıran bunu önbelleğe alır.
/// 2. [filterLedger] — UCUZ kısım (tek `where`). Her filtre değişiminde.
library;

import 'package:cunehat/core/utils/text_search.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// Cüzdanın TAM geçmişinden defter görünümü. Filtre UYGULANMAZ.
///
/// [transactions] çağıran tarafından cüzdana göre süzülmüş olmalıdır:
/// running balance çapası (güncel bakiye) tam geçmiş üzerinde kurulur, yoksa
/// hiçbir tarih aralığında doğru çıkmaz.
List<TransactionWithBalance> buildLedger({
  required List<TransactionEntity> transactions,
  required double currentBalance,
}) {
  return buildLedgerView(
    allTransactions: transactions,
    currentBalance: currentBalance,
  );
}

/// Defter üzerine mod + dönem + kategori + tutar + arama filtrelerini uygular.
///
/// [categoryLabels] `tag` → görünen ad; arama kategori ADINDA da eşleşsin diye
/// gerekir (kullanıcı "market" yazınca başlığı "ŞOK 4712" olan satır da
/// gelmeli).
///
/// [applyDateWindow] false verilirse dönem UYGULANMAZ; takvim görünümü tüm
/// geçmişi görür ve dönemi kendi çizer.
List<TransactionWithBalance> filterLedger({
  required List<TransactionWithBalance> ledger,
  required CombinedFilter filter,
  Map<String, String> categoryLabels = const {},
  bool applyDateWindow = true,
}) {
  final mode = filter.viewFilter.financeMode;
  final categories = filter.dataFilter.selectedCategories;
  final priceRange = filter.dataFilter.priceRange;
  final query = foldTr(filter.dataFilter.searchQuery ?? '');
  final period = DateTimeRange(
    start: filter.viewFilter.startDate,
    end: filter.viewFilter.endDate,
  );

  return ledger.where((e) {
    final t = e.transaction;

    if (applyDateWindow && !isDayInRange(t.date, period)) return false;

    if (mode == FinanceMode.expense && !t.isExpense) return false;
    if (mode == FinanceMode.income && !t.isIncome) return false;

    if (categories.isNotEmpty && !categories.contains(t.tag)) return false;

    if (priceRange != null && !priceRange.isInRange(t.amount)) return false;

    if (query.isNotEmpty && !_matchesQuery(t, query, categoryLabels)) {
      return false;
    }

    return true;
  }).toList();
}

/// [buildLedger] + [filterLedger]. Defterin önbelleğe alınmadığı yerler için
/// (testler, tek seferlik hesaplar).
List<TransactionWithBalance> applyTransactionFilters({
  required List<TransactionEntity> transactions,
  required double currentBalance,
  required CombinedFilter filter,
  Map<String, String> categoryLabels = const {},
  bool applyDateWindow = true,
}) {
  return filterLedger(
    ledger: buildLedger(
      transactions: transactions,
      currentBalance: currentBalance,
    ),
    filter: filter,
    categoryLabels: categoryLabels,
    applyDateWindow: applyDateWindow,
  );
}

/// Arama alanları: başlık, kategorinin görünen adı ve (varsa) bankanın dekont
/// numarası. Tutar bilerek DIŞARIDA — "500" yazan kullanıcı 1.500 ve 5.000'i
/// de eşleştirip listeyi gürültüye boğuyor; tutar için tutar aralığı var.
bool _matchesQuery(
  TransactionEntity t,
  String foldedQuery,
  Map<String, String> categoryLabels,
) {
  if (matchesFolded(t.title, foldedQuery)) return true;
  final label = categoryLabels[t.tag] ?? t.tag;
  if (matchesFolded(label, foldedQuery)) return true;
  final reference = t.reference;
  if (reference != null && matchesFolded(reference, foldedQuery)) return true;
  return false;
}
