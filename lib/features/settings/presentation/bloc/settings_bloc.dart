// lib/features/settings/presentation/bloc/settings_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/settings/domain/repository/settings_repository.dart';
import 'package:cunehat/features/settings/domain/usecases/migration_usecases.dart';
import 'package:equatable/equatable.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository repository;

  StreamSubscription<MigrationStatus>? _migrationSubscription;

  SettingsBloc(this.repository) : super(const SettingsInitialSt()) {
    // ========== LOAD STORAGE MODE ==========
    on<LoadStorageModeEvent>((event, emit) async {
      try {
        final mode = await GetStorageModeUseCase(repository).call();
        emit(StorageModeLoadedSt(mode));
      } catch (e) {
        emit(SettingsErrorSt('Ayarlar yüklenemedi: $e'));
      }
    });

    // ========== CHANGE STORAGE MODE (with migration) ==========
    on<ChangeStorageModeEvent>((event, emit) async {
      emit(const MigrationInProgressSt(progress: 0.0, step: 'Başlatılıyor...'));

      // Listen to migration progress
      _migrationSubscription?.cancel();
      _migrationSubscription =
          WatchMigrationStatusUseCase(repository).call().listen((status) {
        if (status.isInProgress) {
          add(_MigrationProgressEvent(status));
        } else if (status.error != null) {
          add(_MigrationErrorEvent(status.error!));
        }
      });

      try {
        await SetStorageModeUseCase(repository).call(
          userId: event.userId,
          newMode: event.newMode,
        );

        emit(MigrationCompletedSt(event.newMode));
      } catch (e) {
        emit(SettingsErrorSt('Migration hatası: $e'));
      } finally {
        await _migrationSubscription?.cancel();
      }
    });

    // ========== INTERNAL EVENTS ==========
    on<_MigrationProgressEvent>((event, emit) {
      emit(MigrationInProgressSt(
        progress: event.status.progress,
        step: event.status.currentStep ?? '',
      ));
    });

    on<_MigrationErrorEvent>((event, emit) {
      emit(SettingsErrorSt(event.error));
    });
  }

  @override
  Future<void> close() async {
    await _migrationSubscription?.cancel();
    return super.close();
  }
}
