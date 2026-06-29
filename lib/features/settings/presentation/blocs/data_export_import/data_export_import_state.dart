import 'package:equatable/equatable.dart';

/// Widget katmanında l10n ile çevrilen dışa/içe aktarım mesaj tipleri.
enum DataExportMessageType {
  exportSuccess,
  importSuccess,
  fullBackupExportSuccess,
  fullBackupImportSuccess,
  fullBackupShareSuccess,
  fullBackupCancelled,
  noTransactionsToExport,
  noValidTransactionsInCsv,
}

abstract class DataExportImportState extends Equatable {
  const DataExportImportState();

  @override
  List<Object> get props => [];
}

class DataExportImportInitial extends DataExportImportState {}

class DataExportImportLoading extends DataExportImportState {}

class DataExportImportSuccess extends DataExportImportState {
  /// Lokalize edilmiş mesaj tipi. Widget'ta l10n lookup ile çevrilir.
  final DataExportMessageType messageType;

  /// İçe aktarımda atlanan satır sayısı (0 ise ek bilgi gösterilmez).
  final int skippedRows;

  const DataExportImportSuccess(this.messageType, {this.skippedRows = 0});

  @override
  List<Object> get props => [messageType, skippedRows];
}

class DataExportImportError extends DataExportImportState {
  final String message;

  const DataExportImportError(this.message);

  @override
  List<Object> get props => [message];
}
