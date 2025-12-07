// // lib/injection_container.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:cunehat/features/finance_transections/data/datasources/transaction_remote_datasource.dart';
// import 'package:cunehat/features/finance_transections/data/repositories/transaction_repository_impl.dart';
// import 'package:cunehat/features/finance_transections/domain/repositories/transaction_repository.dart';
// import 'package:cunehat/features/finance_transections/domain/usecases/add_transaction_usecase.dart';
// import 'package:cunehat/features/finance_transections/domain/usecases/delete_transaction_usecase.dart';
// import 'package:cunehat/features/finance_transections/domain/usecases/get_transactions_grouped_usecase.dart';
// import 'package:cunehat/features/finance_transections/domain/usecases/update_transaction_usecase.dart';
// import 'package:cunehat/features/finance_transections/presentation/bloc/transection_bloc.dart';
// import 'package:get_it/get_it.dart';

// // Core
// import 'core/network/network_info.dart';

// // Transaction Feature

// final sl = GetIt.instance;

// Future<void> init() async {
//   // ==========================================
//   // CORE
//   // ==========================================

//   // Network Info
//   sl.registerLazySingleton<NetworkInfo>(
//     () => NetworkInfoImpl(sl()),
//   );

//   // ==========================================
//   // TRANSACTION FEATURE
//   // ==========================================

//   // Bloc
//   sl.registerFactory(
//     () => TransactionBloc(
//       getTransactionsGrouped: sl(),
//       addTransaction: sl(),
//       updateTransaction: sl(),
//       deleteTransaction: sl(),
//     ),
//   );

//   // Use Cases
//   sl.registerLazySingleton(() => GetTransactionsGroupedUseCase(sl()));
//   sl.registerLazySingleton(() => AddTransactionUseCase(sl()));
//   sl.registerLazySingleton(() => UpdateTransactionUseCase(sl()));
//   sl.registerLazySingleton(() => DeleteTransactionUseCase(sl()));

//   // Repository
//   sl.registerLazySingleton<TransactionRepository>(
//     () => TransactionRepositoryImpl(
//       remoteDataSource: sl(),
//       networkInfo: sl(),
//     ),
//   );

//   // Data Sources
//   sl.registerLazySingleton<TransactionRemoteDataSource>(
//     () => TransactionRemoteDataSourceImpl(firestore: sl()),
//   );

//   // ==========================================
//   // EXTERNAL
//   // ==========================================

//   // Firebase Firestore
//   sl.registerLazySingleton(() => FirebaseFirestore.instance);

//   // Connectivity
//   sl.registerLazySingleton(() => Connectivity());
// }
