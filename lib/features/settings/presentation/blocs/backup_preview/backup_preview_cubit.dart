import 'package:bloc/bloc.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:cunehat/core/services/drive_backup_result.dart';
import 'package:cunehat/core/services/google_drive_backup_service.dart';
import 'package:cunehat/core/services/local_backup_service.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/features/settings/presentation/blocs/backup_preview/backup_preview_state.dart';
import 'package:injectable/injectable.dart';

/// Yedek önizleme akışı: Drive'daki kopyaları listeler, seçilen kopyanın (ya da
/// cihazdaki bir dosyanın) içeriğini İNDİRİP ÖZETLER — yazmadan — ve kullanıcı
/// onaylarsa geri yükler.
///
/// Bu ekranın varlık sebebi `drive.appdata`: yedek Drive arayüzünde görünmez,
/// yani geri yüklemeden önce içine bakmanın başka yolu yok. "Üzerine geri yükle
/// ve gör" yıkıcı bir teşhis yöntemiydi.
@injectable
class BackupPreviewCubit extends Cubit<BackupPreviewState> {
  final GoogleDriveBackupService _drive;
  final DataSerializationService _data;
  final LocalBackupService _localBackup;
  final TransactionsChangedNotifier _transactionsChanged;
  final CategoriesChangedNotifier _categoriesChanged;

  BackupPreviewCubit(
    this._drive,
    this._data,
    this._localBackup,
    this._transactionsChanged,
    this._categoriesChanged,
  ) : super(const BackupPreviewListLoading());

  // ==================================================================== liste

  Future<void> loadList() async {
    emit(const BackupPreviewListLoading());
    // Ekran ayarlardan açılıyor: kullanıcı zaten "yedeklerimi göster" dedi,
    // gerekirse hesap seçici açılabilir.
    final result = await _drive.listBackups(interactive: true);
    if (!result.isSuccess) {
      emit(BackupPreviewListFailed(result.status));
      return;
    }
    emit(BackupPreviewListLoaded(result.data ?? const []));
  }

  // ==================================================================== detay

  Future<void> openDriveBackup(DriveBackupFile file) async {
    emit(const BackupPreviewDetailLoading());

    final download = await _drive.downloadBackup(file.id);
    if (!download.isSuccess) {
      emit(BackupPreviewDetailFailed(download.status));
      return;
    }

    await _emitDetail(
      source: DriveBackupSource(file),
      rawJson: download.data!,
    );
  }

  /// Cihazdaki bir `.json` yedeğini önizler. Kullanıcı seçiciyi kapatırsa
  /// liste görünümüne dönülür — hata gösterilmez.
  Future<void> openDeviceFile() async {
    final pick = await _localBackup.pickBackupJson();

    switch (pick.status) {
      case LocalBackupStatus.cancelled:
        return;
      case LocalBackupStatus.success:
        emit(const BackupPreviewDetailLoading());
        await _emitDetail(
          source: DeviceFileBackupSource(pick.fileName!),
          rawJson: pick.content!,
        );
      default:
        emit(const BackupPreviewDetailFailed(DriveOperationStatus.corrupt));
    }
  }

  Future<void> _emitDetail({
    required BackupPreviewSource source,
    required String rawJson,
  }) async {
    final inspection = _data.inspectBackup(rawJson);
    final deviceSummary = await _data.currentDataSummary();

    emit(BackupPreviewDetailLoaded(
      source: source,
      inspection: inspection,
      deviceSummary: deviceSummary,
      rawJson: rawJson,
    ));
  }

  // =================================================================== eylem

  /// Önizlenen yedeği geri yükler. Sonucu DÖNER (tek seferlik mesajlar için
  /// state'e gömmek yerine): çağıran sayfa mesajı gösterir, cubit yalnız
  /// görünümü sürer.
  Future<DriveOperationStatus> restoreCurrent({String? userId}) async {
    final current = state;
    if (current is! BackupPreviewDetailLoaded) {
      return DriveOperationStatus.corrupt;
    }

    emit(const BackupPreviewRestoring());
    final result = await _data.importDataFromJson(current.rawJson);

    if (result.isSuccess) {
      // Geri yükleme YALNIZ defteri değil kategori tercihlerini de değiştirir;
      // ikisi ayrı kanallardan yayınlanır. Kategori kanalı bildirilmediği için
      // eskiden açık sayfalar eski kategori adlarını basmaya devam ediyor ve
      // uygulama "lütfen yeniden başlatın" demek zorunda kalıyordu.
      _transactionsChanged.notify(userId: userId);
      _categoriesChanged.notify();
    }

    // Başarıda da hatada da listeye dön: detay ekranındaki özet artık cihazın
    // gerçek durumunu yansıtmıyor.
    emit(BackupPreviewDetailLoaded(
      source: current.source,
      inspection: current.inspection,
      deviceSummary: await _data.currentDataSummary(),
      rawJson: current.rawJson,
    ));

    return switch (result.status) {
      DataRestoreStatus.success => DriveOperationStatus.success,
      DataRestoreStatus.versionMismatch => DriveOperationStatus.versionMismatch,
      DataRestoreStatus.invalidFormat => DriveOperationStatus.corrupt,
      DataRestoreStatus.writeFailure => DriveOperationStatus.writeFailure,
    };
  }

  /// Tek bir Drive kopyasını siler ve listeyi tazeler.
  Future<DriveOperationStatus> deleteDriveBackup(DriveBackupFile file) async {
    final result = await _drive.deleteBackup(file.id);
    if (result.isSuccess) await loadList();
    return result.status;
  }
}
