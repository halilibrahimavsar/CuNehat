import 'dart:math';
import 'package:hive/hive.dart';

part 'debt_model.g.dart';

@HiveType(typeId: 5)
enum DebtType {
  @HiveField(0)
  bankLoan,

  @HiveField(1)
  installmentDebt,

  @HiveField(2)
  personalDebt,

  @HiveField(3)
  otherDebt
}

@HiveType(typeId: 6)
class Debt {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String walletId;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final DebtType type;

  @HiveField(5)
  final double principalAmount;

  @HiveField(6)
  final double interestRate;

  @HiveField(7)
  final int termMonths;

  @HiveField(8)
  final DateTime startDate;

  @HiveField(9)
  final DateTime? dueDate;

  @HiveField(10)
  final String? bankName;

  @HiveField(11)
  final String? personName;

  @HiveField(12)
  final int latePaymentDays;

  @HiveField(13)
  final double latePaymentInterest;

  @HiveField(14)
  final List<Payment> payments;

  @HiveField(15)
  final bool isPaid;

  @HiveField(16)
  final String? notes;

  Debt({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.title,
    required this.type,
    required this.principalAmount,
    required this.interestRate,
    required this.termMonths,
    required this.startDate,
    this.dueDate,
    this.bankName,
    this.personName,
    this.latePaymentDays = 0,
    this.latePaymentInterest = 0,
    this.payments = const [],
    this.isPaid = false,
    this.notes,
  });

  double get remainingAmount {
    double paid = payments.fold(0, (sum, payment) => sum + payment.amount);
    return (principalAmount + totalInterest) - paid;
  }

  double get totalInterest {
    // Basit faiz hesaplama
    double monthlyRate = interestRate / 100 / 12;
    return principalAmount * monthlyRate * termMonths;
  }

  double get monthlyPayment {
    // Aylık ödeme hesaplama
    double monthlyRate = interestRate / 100 / 12;
    if (monthlyRate == 0) {
      return principalAmount / termMonths;
    }
    return principalAmount *
        monthlyRate *
        (pow(1 + monthlyRate, termMonths) /
            (pow(1 + monthlyRate, termMonths) - 1));
  }
}

@HiveType(typeId: 2)
class Payment {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String? notes;

  Payment({
    required this.date,
    required this.amount,
    this.notes,
  });
}
