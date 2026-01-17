import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/data/models/investment_type_adapter.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_type_adapter.dart';
import 'package:cunehat/features/investments/presentation/widgets/color_adapter.dart';

/// Uygulama başlangıcında gereken tüm başlatma işlemleri
class AppInitialization {
  static Future<void> initialize() async {
    await _initializeFirebase();
    await _initializeHive();
    await _initializeDateFormatting();
  }

  static Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  static Future<void> _initializeHive() async {
    await Hive.initFlutter();
    _registerTypeAdapters();
  }

  static Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('tr_TR');
  }

  static void _registerTypeAdapters() {
    Hive.registerAdapter(WalletModelAdapter()); // TypeId 0
    Hive.registerAdapter(TransactionModelAdapter()); // TypeId 1
    Hive.registerAdapter(TransactionTypeModelAdapter()); // TypeId 2
    Hive.registerAdapter(InvestmentModelAdapter()); // TypeId 4
    Hive.registerAdapter(InvestmentTypeAdapter()); // TypeId 5
    Hive.registerAdapter(DebtModelAdapter()); // TypeId 6
    Hive.registerAdapter(ReceivableModelAdapter()); // TypeId 7
    Hive.registerAdapter(PaymentModelAdapter()); // TypeId 8
    Hive.registerAdapter(DebtTypeAdapter()); // TypeId 10
    Hive.registerAdapter(ColorAdapter()); // TypeId 200
  }
}
