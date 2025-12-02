import 'package:bloc/bloc.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/repository/data_repository.dart';
import 'package:equatable/equatable.dart';

part 'settings_events.dart';
part 'settings_states.dart';

// ============ BLOC ============
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final DataRepository _repository;

  SettingsBloc({required DataRepository repository})
      : _repository = repository,
        super(SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<ChangeStorageModeEvent>(_onChangeStorageMode);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());

    try {
      final storageMode = _repository.getStorageMode();
      final pendingCount = _repository.getPendingSyncCount();

      emit(SettingsLoaded(
        storageMode: storageMode,
        pendingSyncCount: pendingCount,
      ));
    } catch (e) {
      emit(SettingsError('Ayarlar yüklenirken hata: ${e.toString()}'));
    }
  }

  Future<void> _onChangeStorageMode(
    ChangeStorageModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final currentMode = _repository.getStorageMode();

    // No change needed
    if (currentMode == event.newMode) {
      return;
    }

    try {
      // LOCAL → CLOUD
      if (event.newMode == StorageMode.cloud) {
        emit(const MigrationInProgress('Veriler buluta taşınıyor...'));

        await _repository.migrateStorage(event.newMode);

        emit(MigrationSuccess(StorageMode.cloud));
      }
      // CLOUD → LOCAL
      else if (event.newMode == StorageMode.local) {
        emit(const MigrationInProgress('Bulut verileri indiriliyor...'));

        await _repository.migrateStorage(event.newMode);

        emit(MigrationSuccess(StorageMode.local));
      }

      // Reload settings
      add(LoadSettingsEvent());
    } catch (e) {
      emit(SettingsError('Geçiş başarısız: ${e.toString()}'));

      // Reload current settings
      add(LoadSettingsEvent());
    }
  }
}
