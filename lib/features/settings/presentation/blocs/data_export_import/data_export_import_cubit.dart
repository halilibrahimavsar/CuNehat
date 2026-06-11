import 'package:bloc/bloc.dart';
import 'package:cunehat/core/services/csv_service.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import 'data_export_import_state.dart';

@injectable
class DataExportImportCubit extends Cubit<DataExportImportState> {
  final CsvService csvService;
  final TransactionsRepository transactionsRepository;
  final WalletRepository walletRepository;

  DataExportImportCubit({
    required this.csvService,
    required this.transactionsRepository,
    required this.walletRepository,
  }) : super(DataExportImportInitial());

  Future<void> exportTransactions(String userId, String walletId) async {
    emit(DataExportImportLoading());
    try {
      final result = await transactionsRepository.getTransactions(
        userId: userId,
        walletId: walletId,
      );

      await result.fold((l) async => emit(DataExportImportError(l.message)),
          (r) async {
        if (r.isEmpty) {
          emit(const DataExportImportError(
              "Dışa aktarılacak işlem bulunamadı."));
          return;
        }
        await csvService.exportTransactionsToCSV(r);
        emit(const DataExportImportSuccess(
            "İşlemler başarıyla dışa aktarıldı."));
      });
    } catch (e) {
      emit(DataExportImportError(e.toString()));
    }
  }

  Future<void> importTransactions(String userId) async {
    emit(DataExportImportLoading());
    try {
      final importedTransactions =
          await csvService.importTransactionsFromCSV(userId);
      if (importedTransactions == null) {
        emit(DataExportImportInitial()); // User cancelled
        return;
      }

      if (importedTransactions.isEmpty) {
        emit(const DataExportImportError(
            "CSV dosyasında geçerli işlem bulunamadı."));
        return;
      }

      // Create a new wallet
      final newWallet = WalletEntity(
        id: const Uuid().v4(),
        userId: userId,
        name:
            "İçe Aktarılan Cüzdan - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
        balance: 0,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: "0xFF4CAF50",
        iconName: "wallet",
        createdAt: DateTime.now(),
      );

      final walletResult = await walletRepository.createWallet(newWallet);

      await walletResult.fold(
          (l) async => emit(
              DataExportImportError("Cüzdan oluşturulamadı: ${l.message}")),
          (newWalletId) async {
        // Add transactions
        for (var t in importedTransactions) {
          await transactionsRepository
              .addTransaction(t.copyWith(walletId: newWalletId));
        }

        // Set as active wallet
        await walletRepository.setActiveWallet(
            userId: userId, newActiveWalletId: newWalletId);

        emit(const DataExportImportSuccess(
            "Veriler başarıyla içe aktarıldı. Yeni cüzdan oluşturuldu ve seçildi."));
      });
    } catch (e) {
      emit(DataExportImportError(e.toString()));
    }
  }
}
