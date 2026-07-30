import 'package:bloc/bloc.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/core/services/csv_service.dart';
import 'package:cunehat/core/services/local_backup_service.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import 'data_export_import_state.dart';

@injectable
class DataExportImportCubit extends Cubit<DataExportImportState> {
  final CsvService csvService;
  final LocalBackupService localBackupService;
  final TransactionsRepository transactionsRepository;
  final WalletRepository walletRepository;
  final WalletMetricsService walletMetricsService;
  final TransactionsChangedNotifier transactionsChangedNotifier;
  final CategoriesChangedNotifier categoriesChangedNotifier;

  DataExportImportCubit({
    required this.csvService,
    required this.localBackupService,
    required this.transactionsRepository,
    required this.walletRepository,
    required this.walletMetricsService,
    required this.transactionsChangedNotifier,
    required this.categoriesChangedNotifier,
  }) : super(DataExportImportInitial());

  Future<void> exportFullBackupToDevice() async {
    emit(DataExportImportLoading());
    final result = await localBackupService.exportToDevice();
    _emitLocalBackupResult(
      result,
      successType: DataExportMessageType.fullBackupExportSuccess,
    );
  }

  Future<void> shareFullBackup({String? shareText}) async {
    emit(DataExportImportLoading());
    final result = await localBackupService.shareBackup(shareText: shareText);
    _emitLocalBackupResult(
      result,
      successType: DataExportMessageType.fullBackupShareSuccess,
    );
  }

  Future<void> importFullBackupFromDevice({String? userId}) async {
    emit(DataExportImportLoading());
    final result = await localBackupService.importFromDevice();
    if (result.isSuccess) {
      // Geri yükleme defteri VE kategori tercihlerini değiştirir; bunlar ayrı
      // yayın kanalları. Kategori kanalı bildirilmediği için açık sayfalar
      // eski kategori adlarını basmaya devam ediyordu.
      transactionsChangedNotifier.notify(userId: userId);
      categoriesChangedNotifier.notify();
    }
    _emitLocalBackupResult(
      result,
      successType: DataExportMessageType.fullBackupImportSuccess,
    );
  }

  Future<void> exportTransactions(String userId, String walletId,
      {String? shareText}) async {
    emit(DataExportImportLoading());
    try {
      final result = await transactionsRepository.getTransactions(
        userId: userId,
        walletId: walletId,
      );

      await result.fold((l) async => emit(DataExportImportError(l.message)),
          (r) async {
        if (r.isEmpty) {
          emit(const DataExportImportSuccess(
              DataExportMessageType.noTransactionsToExport));
          return;
        }
        await csvService.exportTransactionsToCSV(r, shareText: shareText);
        emit(
            const DataExportImportSuccess(DataExportMessageType.exportSuccess));
      });
    } catch (e) {
      emit(DataExportImportError(e.toString()));
    }
  }

  Future<void> importTransactions(String userId) async {
    emit(DataExportImportLoading());
    try {
      final importResult = await csvService.importTransactionsFromCSV(userId);
      if (importResult == null) {
        emit(DataExportImportInitial()); // User cancelled
        return;
      }

      final importedTransactions = importResult.transactions;
      if (importedTransactions.isEmpty) {
        emit(const DataExportImportSuccess(
            DataExportMessageType.noValidTransactionsInCsv));
        return;
      }

      // Tarih bazlı isim oluşturma — prefix ARB'den widget katmanında alınır.
      final now = DateTime.now();
      final newWallet = WalletEntity(
        id: const Uuid().v4(),
        userId: userId,
        name: "importedWallet-${now.day}-${now.month}-${now.year}",
        balance: 0,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: "0xFF4CAF50",
        iconName: "account_balance_wallet",
        createdAt: DateTime.now(),
        openingBalance: 0,
      );

      final walletResult = await walletRepository.createWallet(newWallet);

      await walletResult
          .fold((l) async => emit(DataExportImportError(l.message)),
              (newWalletId) async {
        // Add transactions
        for (var t in importedTransactions) {
          await transactionsRepository
              .addTransaction(t.copyWith(walletId: newWalletId));
        }

        // Bakiye, eklenen işlemlerin defterinden hesaplansın; aksi halde
        // cüzdan 0 bakiyeyle görünür.
        await walletMetricsService.syncBalance(newWalletId);

        // Set as active wallet
        await walletRepository.setActiveWallet(
            userId: userId, newActiveWalletId: newWalletId);

        transactionsChangedNotifier.notify();

        emit(DataExportImportSuccess(
          DataExportMessageType.importSuccess,
          skippedRows: importResult.skippedRows,
        ));
      });
    } catch (e) {
      emit(DataExportImportError(e.toString()));
    }
  }

  void _emitLocalBackupResult(
    LocalBackupResult result, {
    required DataExportMessageType successType,
  }) {
    switch (result.status) {
      case LocalBackupStatus.success:
        emit(DataExportImportSuccess(successType));
        return;
      case LocalBackupStatus.cancelled:
        emit(const DataExportImportSuccess(
          DataExportMessageType.fullBackupCancelled,
        ));
        return;
      case LocalBackupStatus.versionMismatch:
        emit(DataExportImportVersionMismatch('${result.foundVersion}'));
        return;
      case LocalBackupStatus.failure:
        emit(DataExportImportError(
            result.error?.toString() ?? 'Yedekleme işlemi tamamlanamadı.'));
        return;
    }
  }
}
