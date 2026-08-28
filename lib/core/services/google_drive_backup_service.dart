import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cunehat/core/services/backup_summary.dart';
import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:cunehat/core/services/drive_backup_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

/// Kullanıcının kendi Drive'ındaki gizli uygulama klasörüne (`appDataFolder`)
/// jenerasyonlu yedek yazar/okur.
///
/// Tasarım kararları ve nedenleri:
///
/// * **Jenerasyon, yerinde güncelleme değil.** Önceden tek bir
///   `cunehat_backup.json` vardı ve her yedekleme onu yerinde PATCH ediyordu:
///   yükleme yarıda koparsa geriye dönülecek TEK kopya bozuluyordu. Artık her
///   yedek yeni bir dosya; son [maxGenerations] tanesi tutulur.
/// * **Tek istekte multipart.** Eski akış önce boş dosya yaratıp (metadata)
///   sonra içeriği ayrı PATCH ile yolluyordu; ikinci adım başarısız olunca
///   Drive'da 0 baytlı bir "yedek" kalıyordu ve sonraki geri yükleme onu bulup
///   "yedek yok" diyordu. Metadata + içerik artık tek atomik istekte gider.
/// * **Yükleme sonrası doğrulama.** Drive'ın döndürdüğü `md5Checksum` sunucuda
///   saklanan içerikten hesaplanır; yerel md5 ile karşılaştırmak, dosyayı
///   yeniden indirmeden yapılabilecek gerçek bir geri-okuma doğrulamasıdır.
/// * **Boş veri kapısı.** Yeni kurulumda "Yedekle"ye basmak, dolu uzak yedeği
///   boşla ezen bir veri kaybı yoluydu. Artık [DriveOperationStatus.emptyLocalData]
///   ile reddedilir; kullanıcı bilerek isterse `allowEmpty` ile geçer.
/// * **`bool` yerine tipli sonuç.** Bkz. [DriveOperationStatus].
@lazySingleton
class GoogleDriveBackupService {
  static const List<String> scopes = <String>[
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  /// Sorgu öneki. Yeni dosyalar `cunehat_backup_<ts>.json`; önek alt tire
  /// içermediği için eski tek-dosya düzeninden kalan `cunehat_backup.json` da
  /// listelenir (görünmez yetim bırakmamak için — ayrı bir uyumluluk kodu yok,
  /// yalnızca süzgeç onu dışlamıyor).
  static const String backupNamePrefix = 'cunehat_backup';

  /// Drive'da tutulacak jenerasyon sayısı. Yedekler birkaç yüz KB; beş kopya
  /// kullanıcının kotasında kayda değer yer tutmaz, buna karşılık "dün iyiydi"
  /// senaryosunu kurtarır.
  static const int maxGenerations = 5;

  static const Duration defaultShortTimeout = Duration(seconds: 30);
  static const Duration defaultTransferTimeout = Duration(seconds: 90);

  /// Testler gerçek 30/90 saniyeyi beklemesin diye enjekte edilebilir.
  final Duration _shortTimeout;
  final Duration _transferTimeout;

  static const String _fileFields =
      'id,name,size,modifiedTime,md5Checksum,appProperties';

  final GoogleSignIn _googleSignIn;
  final http.Client _httpClient;
  final DataSerializationService _dataSerializationService;

  @factoryMethod
  GoogleDriveBackupService(this._dataSerializationService)
      : _googleSignIn = GoogleSignIn(scopes: scopes),
        _httpClient = http.Client(),
        _shortTimeout = defaultShortTimeout,
        _transferTimeout = defaultTransferTimeout;

  @visibleForTesting
  GoogleDriveBackupService.withMocks({
    required GoogleSignIn googleSignIn,
    required http.Client httpClient,
    required DataSerializationService dataSerializationService,
    Duration shortTimeout = defaultShortTimeout,
    Duration transferTimeout = defaultTransferTimeout,
  })  : _googleSignIn = googleSignIn,
        _httpClient = httpClient,
        _dataSerializationService = dataSerializationService,
        _shortTimeout = shortTimeout,
        _transferTimeout = transferTimeout;

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  @disposeMethod
  void dispose() => _httpClient.close();

  // ===================================================================== auth

  /// Kullanıcı etkileşimi olmadan mevcut oturumu tazeler.
  ///
  /// `suppressErrors: false` BİLEREK: varsayılan `true`, `DEVELOPER_ERROR`
  /// dahil her istisnayı yutup `null` döndürüyor ve kart yalnızca "bağlı değil"
  /// diyebiliyordu — OAuth istemcisi yanlış yapılandırıldığında sebebi
  /// görmenin hiçbir yolu yoktu.
  Future<DriveResult<GoogleSignInAccount>> silentSignIn() {
    return _guard(() async {
      final account = await _googleSignIn.signInSilently(suppressErrors: false);
      _currentUser = account;
      // Sonucu da bas: yalnız hata yolları günlüğe düşünce "hiçbir şey
      // basılmadı" hâli üç ayrı sonucu birden gizliyor (başarı / null / hiç
      // tamamlanmayan Future). E-posta BASILMAZ, yalnız varlığı.
      debugPrint('GoogleDriveBackupService silentSignIn -> '
          '${account == null ? 'null (notSignedIn)' : 'hesap alındı'}');
      if (account == null) {
        return const DriveResult<GoogleSignInAccount>.failure(
          DriveOperationStatus.notSignedIn,
        );
      }
      return DriveResult<GoogleSignInAccount>.success(account);
    });
  }

  /// Hesap seçiciyi açar. Kullanıcı seçiciyi kapatırsa sonuç
  /// [DriveOperationStatus.cancelled] olur — "bağlantı başarısız" değil.
  Future<DriveResult<GoogleSignInAccount>> signIn() {
    return _guard(() async {
      debugPrint('GoogleDriveBackupService signIn -> başladı');
      final account = await _googleSignIn.signIn();
      _currentUser = account;
      // Bkz. [silentSignIn]: bu satır olmadan "hesap seçici açılıp kapandı,
      // sonra hiçbir şey" durumu teşhis edilemiyor — Future'ın hiç
      // tamamlanmadığı hâl ile null döndüğü hâl birbirinden ayrılmıyor.
      debugPrint('GoogleDriveBackupService signIn -> '
          '${account == null ? 'null (cancelled)' : 'hesap alındı'}');
      if (account == null) {
        return const DriveResult<GoogleSignInAccount>.failure(
          DriveOperationStatus.cancelled,
        );
      }
      return DriveResult<GoogleSignInAccount>.success(account);
    });
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  // ================================================================== listing

  /// Drive'daki yedekleri yeniden eskiye sıralar. İçerik indirilmez; sayımlar
  /// `appProperties`'ten gelir.
  /// [limit] varsayılan olarak gösterilen jenerasyon sayısıdır. Silme gibi
  /// "hepsini kapsa" işlemleri daha yüksek bir sınır geçer: budama bir kez
  /// başarısız olduysa Drive'da 5'ten fazla kopya kalmış olabilir ve "tümünü
  /// sil" geride görünmez dosya bırakmamalı.
  Future<DriveResult<List<DriveBackupFile>>> listBackups({
    bool interactive = false,
    int limit = maxGenerations,
  }) {
    return _guard(() async {
      final account = await _requireAccount(interactive: interactive);
      if (account != null) return account.castFailure<List<DriveBackupFile>>();

      final url = Uri.https('www.googleapis.com', '/drive/v3/files', {
        'spaces': 'appDataFolder',
        'q': "name contains '$backupNamePrefix' and trashed=false",
        'orderBy': 'modifiedTime desc',
        'pageSize': '$limit',
        'fields': 'files($_fileFields)',
      });

      final response = await _authorized(
        (headers) => _httpClient.get(url, headers: headers),
        timeout: _shortTimeout,
      );
      if (response.statusCode != 200) throw _failureFor(response);

      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final files = (decoded['files'] as List<dynamic>? ?? const [])
          .map((f) => DriveBackupFile.fromDriveJson(
              Map<String, dynamic>.from(f as Map)))
          .toList();

      return DriveResult<List<DriveBackupFile>>.success(files);
    });
  }

  /// En yeni yedeğin metadata'sı. "Son yedekleme" göstergesinin DOĞRULUK
  /// KAYNAĞI budur: eskiden yerel prefs'te biçimlenmiş bir metin tutuluyordu ve
  /// uygulama yeniden kurulunca "hiç yedek yok" görünüyordu — oysa yedek
  /// Drive'da duruyordu.
  Future<DriveResult<DriveBackupFile>> latestBackup({
    bool interactive = false,
  }) async {
    final listed = await listBackups(interactive: interactive);
    if (!listed.isSuccess) return listed.castFailure<DriveBackupFile>();

    final files = listed.data ?? const <DriveBackupFile>[];
    if (files.isEmpty) {
      return const DriveResult<DriveBackupFile>.failure(
        DriveOperationStatus.notFound,
      );
    }
    return DriveResult<DriveBackupFile>.success(files.first);
  }

  // =================================================================== backup

  /// Yeni bir jenerasyon yükler, doğrular, eskileri budar.
  ///
  /// [allowEmpty] yalnız kullanıcı boş veriyi bilerek yedeklemek istediğinde
  /// (açık ikinci onayla) true geçilir.
  ///
  /// [skipIfContentMd5Matches] verilirse ve dışa aktarılan içeriğin md5'i buna
  /// eşitse yükleme yapılmaz ([DriveOperationStatus.unchanged]). Otomatik yedek
  /// bunu kullanır: her arka plana geçişte aynı veriyi tekrar tekrar yüklemek
  /// hem kotayı hem jenerasyon penceresini boşa harcar (5 kopyanın hepsi aynı
  /// içerik olurdu — "dün iyiydi" senaryosu kaybolurdu).
  Future<DriveResult<DriveBackupFile>> backup({
    BackupOrigin origin = BackupOrigin.manual,
    bool allowEmpty = false,
    bool interactive = true,
    String? skipIfContentMd5Matches,
  }) {
    return _guard(() async {
      // Kapı ÖNCE: oturum açmadan, ağa çıkmadan reddet.
      final summary = await _dataSerializationService.currentDataSummary();
      if (summary.isEmpty && !allowEmpty) {
        return const DriveResult<DriveBackupFile>.failure(
          DriveOperationStatus.emptyLocalData,
        );
      }

      // Dışa aktarma + "değişmedi" kapısı oturum açmadan ÖNCE: değişiklik
      // yoksa hiç ağa çıkmadan dönülür (otomatik yedeğin sık yolu budur).
      final backupJson = await _dataSerializationService.exportDataToJson();
      final bytes = utf8.encode(backupJson);
      final expectedMd5 = md5.convert(bytes).toString();

      if (skipIfContentMd5Matches != null &&
          skipIfContentMd5Matches == expectedMd5) {
        return const DriveResult<DriveBackupFile>.failure(
          DriveOperationStatus.unchanged,
        );
      }

      final account = await _requireAccount(interactive: interactive);
      if (account != null) return account.castFailure<DriveBackupFile>();

      final uploaded = await _uploadGeneration(
        bytes: bytes,
        summary: summary,
        origin: origin,
      );

      final verified = uploaded.md5Checksum != null
          ? uploaded.md5Checksum == expectedMd5
          : uploaded.sizeBytes == bytes.length;
      if (!verified) {
        // Yarım/bozuk jenerasyonu bırakma: sonraki geri yüklemede "en yeni
        // yedek" olarak seçilip kullanıcıyı bozuk veriye götürürdü.
        await _deleteFile(uploaded.id, bestEffort: true);
        return const DriveResult<DriveBackupFile>.failure(
          DriveOperationStatus.verificationFailed,
        );
      }

      await _pruneOldGenerations();
      return DriveResult<DriveBackupFile>.success(uploaded);
    });
  }

  Future<DriveBackupFile> _uploadGeneration({
    required List<int> bytes,
    required BackupSummary summary,
    required BackupOrigin origin,
  }) async {
    const boundary = 'cunehat-backup-boundary-7f3a';
    final metadata = <String, dynamic>{
      'name': _newFileName(),
      'mimeType': 'application/json',
      'parents': <String>['appDataFolder'],
      // appProperties yalnız string değer kabul eder.
      'appProperties': <String, String>{
        'schemaVersion': '${DataSerializationService.schemaVersion}',
        'transactionCount': '${summary.transactionCount}',
        'walletCount': '${summary.walletCount}',
        'origin': origin.name,
      },
    };

    final body = <int>[
      ...utf8.encode(
        '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n',
      ),
      ...utf8.encode(jsonEncode(metadata)),
      ...utf8.encode(
        '\r\n--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n',
      ),
      ...bytes,
      ...utf8.encode('\r\n--$boundary--\r\n'),
    ];

    final url = Uri.https(
        'www.googleapis.com', '/upload/drive/v3/files', <String, String>{
      'uploadType': 'multipart',
      'fields': _fileFields,
    });

    final response = await _authorized(
      (headers) => _httpClient.post(
        url,
        headers: <String, String>{
          ...headers,
          'Content-Type': 'multipart/related; boundary=$boundary',
        },
        body: body,
      ),
      timeout: _transferTimeout,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _failureFor(response);
    }

    return DriveBackupFile.fromDriveJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  /// Son [maxGenerations] dışındakileri siler. Best-effort: budama hatası
  /// yedeğin kendisini başarısız saymamalı — yedek zaten yüklendi ve doğrulandı.
  Future<void> _pruneOldGenerations() async {
    try {
      final url = Uri.https('www.googleapis.com', '/drive/v3/files', {
        'spaces': 'appDataFolder',
        'q': "name contains '$backupNamePrefix' and trashed=false",
        'orderBy': 'modifiedTime desc',
        'pageSize': '100',
        'fields': 'files(id)',
      });
      final response = await _authorized(
        (headers) => _httpClient.get(url, headers: headers),
        timeout: _shortTimeout,
      );
      if (response.statusCode != 200) return;

      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final files = decoded['files'] as List<dynamic>? ?? const [];
      for (final file in files.skip(maxGenerations)) {
        final id = (file as Map)['id'] as String?;
        if (id != null) await _deleteFile(id, bestEffort: true);
      }
    } catch (e, st) {
      debugPrint('GoogleDriveBackupService prune error: $e\n$st');
    }
  }

  String _newFileName() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${backupNamePrefix}_${now.year}${two(now.month)}${two(now.day)}'
        '_${two(now.hour)}${two(now.minute)}${two(now.second)}.json';
  }

  // ================================================================== restore

  /// Yedeğin ham JSON'unu indirir (önizleme bunu kullanır; hiçbir şey yazmaz).
  Future<DriveResult<String>> downloadBackup(String fileId) {
    return _guard(() async {
      final account = await _requireAccount(interactive: false);
      if (account != null) return account.castFailure<String>();
      return DriveResult<String>.success(await _download(fileId));
    });
  }

  /// Belirli bir jenerasyonu geri yükler.
  Future<DriveResult<void>> restoreFrom(String fileId) {
    return _guard(() async {
      final account = await _requireAccount(interactive: true);
      if (account != null) return account.castFailure<void>();

      final content = await _download(fileId);
      final result =
          await _dataSerializationService.importDataFromJson(content);

      return switch (result.status) {
        DataRestoreStatus.success => const DriveResult<void>.success(),
        DataRestoreStatus.versionMismatch => DriveResult<void>.failure(
            DriveOperationStatus.versionMismatch,
            foundSchemaVersion: result.foundVersion,
          ),
        DataRestoreStatus.invalidFormat => DriveResult<void>.failure(
            DriveOperationStatus.corrupt,
            error: result.error,
          ),
        DataRestoreStatus.writeFailure => DriveResult<void>.failure(
            DriveOperationStatus.writeFailure,
            error: result.error,
          ),
      };
    });
  }

  /// En yeni jenerasyonu geri yükler. Yedek yoksa
  /// [DriveOperationStatus.notFound] — "bozuk" ya da "başarısız" değil.
  Future<DriveResult<void>> restoreLatest() async {
    final latest = await latestBackup(interactive: true);
    if (!latest.isSuccess) return latest.castFailure<void>();
    return restoreFrom(latest.data!.id);
  }

  Future<String> _download(String fileId) async {
    final url = Uri.https('www.googleapis.com', '/drive/v3/files/$fileId', {
      'alt': 'media',
    });
    final response = await _authorized(
      (headers) => _httpClient.get(url, headers: headers),
      timeout: _transferTimeout,
    );
    if (response.statusCode != 200) throw _failureFor(response);

    // `response.body` DEĞİL: package:http, Content-Type'ta charset yoksa
    // yalnız `application/json` için utf8'e düşer, başka her değerde latin1'e.
    // Latin1 çözme hata vermez — sessizce mojibake üretir ve JSON yine parse
    // olurdu, yani tüm Türkçe karakterler fark edilmeden bozulurdu.
    return utf8.decode(response.bodyBytes);
  }

  // =================================================================== delete

  /// Tek bir jenerasyonu siler.
  Future<DriveResult<void>> deleteBackup(String fileId) {
    return _guard(() async {
      final account = await _requireAccount(interactive: true);
      if (account != null) return account.castFailure<void>();
      await _deleteFile(fileId, bestEffort: false);
      return const DriveResult<void>.success();
    });
  }

  /// Drive'daki TÜM yedekleri siler. Yedek zaten yoksa başarı döner.
  Future<DriveResult<void>> deleteAllBackups() {
    return _guard(() async {
      final account = await _requireAccount(interactive: true);
      if (account != null) return account.castFailure<void>();

      final listed = await listBackups(limit: 100);
      if (!listed.isSuccess) return listed.castFailure<void>();

      for (final file in listed.data ?? const <DriveBackupFile>[]) {
        await _deleteFile(file.id, bestEffort: false);
      }
      return const DriveResult<void>.success();
    });
  }

  Future<void> _deleteFile(String fileId, {required bool bestEffort}) async {
    try {
      final url = Uri.https('www.googleapis.com', '/drive/v3/files/$fileId');
      final response = await _authorized(
        (headers) => _httpClient.delete(url, headers: headers),
        timeout: _shortTimeout,
      );
      // 204 = silindi. 404 = zaten yok, istenen son duruma ulaşılmış demektir.
      final ok = response.statusCode == 204 ||
          response.statusCode == 200 ||
          response.statusCode == 404;
      if (!ok && !bestEffort) throw _failureFor(response);
    } catch (e, st) {
      if (!bestEffort) rethrow;
      debugPrint('GoogleDriveBackupService delete($fileId) error: $e\n$st');
    }
  }

  // ================================================================ internals

  /// Oturum yoksa önce sessiz, gerekiyorsa etkileşimli giriş dener.
  /// Başarıda `null`, aksi halde yukarı taşınacak hata sonucunu döner.
  Future<DriveResult<void>?> _requireAccount(
      {required bool interactive}) async {
    if (_currentUser != null) return null;

    final silent = await silentSignIn();
    if (silent.isSuccess) return null;

    // Otomatik yedek gibi arka plan çağrıları asla hesap seçici AÇMAZ.
    if (!interactive) {
      return silent.castFailure<void>();
    }
    // Yapılandırma/ağ hatasında hesap seçici açmak anlamsız: aynı hata
    // kullanıcıya ikinci kez, bu kez "iptal" gibi görünerek dönerdi.
    if (silent.status != DriveOperationStatus.notSignedIn) {
      return silent.castFailure<void>();
    }

    final interactiveResult = await signIn();
    if (interactiveResult.isSuccess) return null;
    return interactiveResult.castFailure<void>();
  }

  Future<Map<String, String>> _headers() async {
    final user = _currentUser;
    if (user == null) {
      throw const _DriveFailure(DriveOperationStatus.notSignedIn);
    }
    return user.authHeaders;
  }

  /// Yetkili istek: 401'de token'ı tazeleyip, 403-kapsam hatasında kapsamı
  /// isteyip BİR kez yeniden dener.
  ///
  /// 401 için `clearAuthCache` çağırmak paketin açık talimatı: "If client runs
  /// into 401 errors using a token, it is expected to call this method and grab
  /// `authHeaders` once again" (google_sign_in). Bu yapılmadığı için token
  /// süresi dolduğunda yedekleme sessizce başarısız oluyordu.
  ///
  /// Kapsam kontrolü neden tepkisel: `canAccessScopes` Android'de
  /// `UnimplementedError` fırlatır (yalnız web'de gerçeklenmiş), bu yüzden
  /// önden sorulamaz — 403 gelince `requestScopes` ile istenir.
  Future<http.Response> _authorized(
    Future<http.Response> Function(Map<String, String> headers) run, {
    required Duration timeout,
  }) async {
    var headers = await _headers();
    var response = await run(headers).timeout(timeout);

    if (response.statusCode == 401) {
      // Not: `clearAuthCache` hesabın üzerindedir, `GoogleSignIn`'in değil —
      // geçersiz token istemci tarafında hesapla birlikte önbelleklenir.
      await _currentUser?.clearAuthCache();
      final refreshed =
          await _googleSignIn.signInSilently(suppressErrors: true);
      if (refreshed == null) {
        throw const _DriveFailure(DriveOperationStatus.authExpired);
      }
      _currentUser = refreshed;
      headers = await refreshed.authHeaders;
      response = await run(headers).timeout(timeout);
      if (response.statusCode == 401) {
        throw const _DriveFailure(DriveOperationStatus.authExpired);
      }
    }

    if (response.statusCode == 403 && _isScopeError(response)) {
      final granted = await _googleSignIn.requestScopes(scopes);
      if (!granted) {
        throw const _DriveFailure(DriveOperationStatus.scopeDenied);
      }
      headers = await _headers();
      response = await run(headers).timeout(timeout);
      if (response.statusCode == 403 && _isScopeError(response)) {
        throw const _DriveFailure(DriveOperationStatus.scopeDenied);
      }
    }

    return response;
  }

  /// Drive hata gövdesindeki `reason` alanı. Kapsam eksikliği ile kota dolması
  /// aynı 403'ü paylaşır ama kullanıcı için tamamen farklı iki durumdur.
  String? _errorReason(http.Response response) {
    try {
      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final error = decoded['error'] as Map<String, dynamic>?;
      final errors = error?['errors'] as List<dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        return (errors.first as Map)['reason'] as String?;
      }
      return error?['status'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Drive API'nin projede kapalı olması da 403 döner (`accessNotConfigured`).
  /// Bunu kapsam eksikliği sanıp `requestScopes` çağırmak boşuna bir izin
  /// ekranı açar (ya da sessizce başarısız olur) ve kullanıcıya "izin
  /// vermedin" der — oysa verebileceği bir izin yoktur.
  bool _isApiNotEnabled(String reason) =>
      reason.contains('accessnotconfigured') ||
      reason.contains('servicedisabled') ||
      reason.contains('service_disabled');

  bool _isScopeError(http.Response response) {
    final reason = _errorReason(response)?.toLowerCase();
    if (reason == null || _isApiNotEnabled(reason)) return false;
    return reason.contains('insufficient') || reason.contains('forbidden');
  }

  _DriveFailure _failureFor(http.Response response) {
    final reason = _errorReason(response)?.toLowerCase() ?? '';
    // Ham `reason` detaya konur: cihaz günlüğünde ("flutter logs") hangi
    // Cloud Console eksiğinin konuştuğu doğrudan görünsün.
    final detail = 'HTTP ${response.statusCode}'
        '${reason.isEmpty ? '' : ' ($reason)'}';
    return switch (response.statusCode) {
      401 => _DriveFailure(DriveOperationStatus.authExpired, detail),
      403 when _isApiNotEnabled(reason) =>
        _DriveFailure(DriveOperationStatus.apiNotEnabled, detail),
      403 when reason.contains('quota') =>
        _DriveFailure(DriveOperationStatus.quotaExceeded, detail),
      403 => _DriveFailure(DriveOperationStatus.scopeDenied, detail),
      404 => _DriveFailure(DriveOperationStatus.notFound, detail),
      _ => _DriveFailure(DriveOperationStatus.serverError, detail),
    };
  }

  /// Tüm dış dünya hatalarını tipli sonuca çevirir. Buradan istisna SIZMAZ:
  /// çağıranların hepsi UI, ve yedekleme akışı kullanıcıyı çökertmemeli.
  Future<DriveResult<T>> _guard<T>(
    Future<DriveResult<T>> Function() body,
  ) async {
    try {
      return await body();
    } on _DriveFailure catch (failure) {
      // Yapılandırma eksiklerinin (kapsam, API kapalı, kota) gerçek Drive
      // sebebi cihaz günlüğüne düşsün; kullanıcıya gösterilen metin
      // sadeleştirilmiş olduğu için teşhis buradan yapılır.
      debugPrint('GoogleDriveBackupService failure: $failure');
      return DriveResult<T>.failure(failure.status, error: failure.detail);
    } on TimeoutException catch (e) {
      return DriveResult<T>.failure(DriveOperationStatus.timeout, error: e);
    } on SocketException catch (e) {
      return DriveResult<T>.failure(DriveOperationStatus.noNetwork, error: e);
    } on http.ClientException catch (e) {
      return DriveResult<T>.failure(DriveOperationStatus.noNetwork, error: e);
    } on PlatformException catch (e) {
      return DriveResult<T>.failure(_mapPlatformException(e), error: e);
    } catch (e, st) {
      debugPrint('GoogleDriveBackupService unexpected error: $e\n$st');
      return DriveResult<T>.failure(DriveOperationStatus.serverError, error: e);
    }
  }

  /// Eklentinin token alma yolunun (`GoogleSignInPlugin.getAccessToken`) hata
  /// kodları. Giriş başarılıyken `authHeaders` bu kodlarla patlayabilir ve
  /// hiçbiri `sign_in_*` ailesinden değildir. Bkz. [DriveOperationStatus.tokenFailed].
  static const Set<String> _tokenErrorCodes = <String>{
    'exception',
    'user_recoverable_auth',
    'failed_to_recover_auth',
  };

  /// Google Sign-In platform hatalarını sınıflandırır.
  ///
  /// `DEVELOPER_ERROR (10)` özel: OAuth Android istemcisi uygulamanın paket adı
  /// + imza SHA-1'i ile eşleşmiyor demektir. Kullanıcının yapabileceği bir şey
  /// yok; "bağlantı başarısız" demek onu boşuna uğraştırır.
  DriveOperationStatus _mapPlatformException(PlatformException e) {
    // Ham kodu HER ZAMAN günlüğe bas. Bu eşlemenin tanımadığı her kod
    // `serverError`a düşüyor ve kullanıcıya "sonra tekrar deneyin" diyor;
    // 2026-08-27'de Drive arızasının teşhisi tam olarak bu yüzden bir gün
    // kaybettirdi — cihazda hatanın gerçek kodunu görmenin hiçbir yolu yoktu.
    debugPrint('GoogleDriveBackupService platform error: '
        'code=${e.code} message=${e.message} details=${e.details}');
    if (e.code == GoogleSignIn.kSignInCanceledError) {
      return DriveOperationStatus.cancelled;
    }
    if (e.code == GoogleSignIn.kNetworkError) {
      return DriveOperationStatus.noNetwork;
    }
    if (e.code == GoogleSignIn.kSignInRequiredError) {
      return DriveOperationStatus.notSignedIn;
    }
    // Kod kontrolünden ÖNCE: `DEVELOPER_ERROR` token yolundan da gelebiliyor,
    // yani `exception` kodunun içinde. Yapılandırma hatası olduğunu bilmek
    // "yeniden bağlan" demekten daha doğru bir teşhis.
    final message = '${e.message ?? ''} ${e.details ?? ''}';
    if (RegExp(r'ApiException:\s*10\b').hasMatch(message) ||
        message.contains('DEVELOPER_ERROR')) {
      return DriveOperationStatus.configError;
    }
    if (_tokenErrorCodes.contains(e.code)) {
      return DriveOperationStatus.tokenFailed;
    }
    return DriveOperationStatus.serverError;
  }
}

/// Servis içi kontrol akışı; dışarı sızmaz ([GoogleDriveBackupService._guard]
/// hepsini [DriveResult]'a çevirir).
class _DriveFailure implements Exception {
  final DriveOperationStatus status;
  final Object? detail;

  const _DriveFailure(this.status, [this.detail]);

  @override
  String toString() => '_DriveFailure($status, $detail)';
}
