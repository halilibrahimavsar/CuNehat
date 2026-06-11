import 'package:equatable/equatable.dart';

abstract class DataExportImportState extends Equatable {
  const DataExportImportState();

  @override
  List<Object> get props => [];
}

class DataExportImportInitial extends DataExportImportState {}

class DataExportImportLoading extends DataExportImportState {}

class DataExportImportSuccess extends DataExportImportState {
  final String message;

  const DataExportImportSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class DataExportImportError extends DataExportImportState {
  final String message;

  const DataExportImportError(this.message);

  @override
  List<Object> get props => [message];
}
