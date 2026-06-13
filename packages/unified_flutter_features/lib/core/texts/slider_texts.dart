import 'package:flutter/foundation.dart';

@immutable
class SliderTexts {
  final String savings;
  final String transactions;
  final String debt;

  const SliderTexts({
    this.savings = 'SAVINGS',
    this.transactions = 'TRANSACTIONS',
    this.debt = 'DEBT',
  });
}
