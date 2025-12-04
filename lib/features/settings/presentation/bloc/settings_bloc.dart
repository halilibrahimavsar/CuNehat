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
    on<LoadStorageModeEvent>(_onLoadStorageMode);
    on<ChangeStorageModeEvent>(_onChangeStorageMode);
    on<_MigrationProgressEvent>(_onMigrationProgress);
    on<_MigrationErrorEvent>(_onMigrationError);
  }

  Future<void> _onLoadStorageMode(
    LoadStorageModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final mode = await GetStorageModeUseCase(repository).call();
      emit(StorageModeLoadedSt(mode));
    } catch (e) {
      emit(SettingsErrorSt('Ayarlar yüklenemedi: $e'));
    }
  }

  Future<void> _onChangeStorageMode(
    ChangeStorageModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      // 1. Cancel any existing subscription
      await _migrationSubscription?.cancel();

      // 2. Start listening to migration status BEFORE starting migration
      _migrationSubscription =
          WatchMigrationStatusUseCase(repository).call().listen((status) {
        if (status.isInProgress) {
          add(_MigrationProgressEvent(status));
        } else if (status.error != null) {
          add(_MigrationErrorEvent(status.error!));
        }
      }, onError: (error) {
        add(_MigrationErrorEvent(error.toString()));
      });

      // 3. Initial progress state
      emit(const MigrationInProgressSt(progress: 0.0, step: 'Hazırlanıyor...'));

      // 4. Execute migration
      await SetStorageModeUseCase(repository).call(
        userId: event.userId,
        newMode: event.newMode,
      );

      // 5. Migration completed successfully
      emit(MigrationCompletedSt(event.newMode));

      // 6. Reload the new mode
      final newMode = await GetStorageModeUseCase(repository).call();
      emit(StorageModeLoadedSt(newMode));
    } catch (e) {
      emit(SettingsErrorSt('Migration hatası: $e'));
    } finally {
      await _migrationSubscription?.cancel();
      _migrationSubscription = null;
    }
  }

  void _onMigrationProgress(
    _MigrationProgressEvent event,
    Emitter<SettingsState> emit,
  ) {
    emit(MigrationInProgressSt(
      progress: event.status.progress,
      step: event.status.currentStep ?? '',
    ));
  }

  void _onMigrationError(
    _MigrationErrorEvent event,
    Emitter<SettingsState> emit,
  ) {
    emit(SettingsErrorSt(event.error));
  }

  @override
  Future<void> close() async {
    await _migrationSubscription?.cancel();
    return super.close();
  }
}
