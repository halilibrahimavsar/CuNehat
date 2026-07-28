import 'dart:convert';
import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

@lazySingleton
class GoogleDriveBackupService {
  final GoogleSignIn _googleSignIn;
  final http.Client _httpClient;
  final DataSerializationService _dataSerializationService;

  @factoryMethod
  GoogleDriveBackupService(this._dataSerializationService)
      : _googleSignIn = GoogleSignIn(
          scopes: [
            'https://www.googleapis.com/auth/drive.appdata',
          ],
        ),
        _httpClient = http.Client();

  @visibleForTesting
  GoogleDriveBackupService.withMocks({
    required GoogleSignIn googleSignIn,
    required http.Client httpClient,
    required DataSerializationService dataSerializationService,
  })  : _googleSignIn = googleSignIn,
        _httpClient = httpClient,
        _dataSerializationService = dataSerializationService;

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Check if user is already signed in
  Future<bool> silentSignIn() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      return _currentUser != null;
    } catch (e, st) {
      debugPrint('GoogleDriveBackupService.silentSignIn error: $e\n$st');
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser != null;
    } catch (e, st) {
      debugPrint('GoogleDriveBackupService.signIn error: $e\n$st');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  /// Kullanıcının Drive'ındaki yedek dosyasını (cunehat_backup.json) siler.
  /// Dosya zaten yoksa silinecek bir şey olmadığından `true` döner.
  /// Hata bacağında `false`, fırlatmaz.
  Future<bool> deleteBackup() async {
    if (_currentUser == null) {
      final signedIn = await signIn();
      if (!signedIn) return false;
    }

    try {
      final headers = await _currentUser!.authHeaders;
      final fileId = await _findBackupFileId(headers);
      if (fileId == null) return true; // yedek yok → no-op başarı

      final deleteUrl = Uri.parse(
        'https://www.googleapis.com/drive/v3/files/$fileId',
      );
      final response = await _httpClient.delete(deleteUrl, headers: headers);

      // 204 No Content = başarılı silme; 200 de kabul edilir.
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e, st) {
      debugPrint('GoogleDriveBackupService.deleteBackup error: $e\n$st');
      return false;
    }
  }

  /// Search for cunehat_backup.json in the AppData folder of user's Google Drive.
  /// Returns the file ID if found, otherwise null.
  Future<String?> _findBackupFileId(Map<String, String> headers) async {
    final url = Uri.parse(
      'https://www.googleapis.com/drive/v3/files?spaces=appDataFolder&q=name=%27cunehat_backup.json%27%20and%20trashed=false',
    );
    final response = await _httpClient.get(url, headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final files = json['files'] as List<dynamic>? ?? [];
      if (files.isNotEmpty) {
        return files.first['id'] as String?;
      }
    }
    return null;
  }

  /// Creates a new backup file metadata entry in the AppData folder.
  /// Returns the file ID.
  Future<String> _createBackupFile(Map<String, String> headers) async {
    final url = Uri.parse('https://www.googleapis.com/drive/v3/files');
    final response = await _httpClient.post(
      url,
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': 'cunehat_backup.json',
        // mimeType açıkça verilir: indirmede Drive dosyanın kayıtlı
        // mimeType'ını Content-Type olarak döndürür ve `application/json`
        // olmayan her değerde package:http gövdeyi latin1 çözerdi.
        'mimeType': 'application/json',
        'parents': ['appDataFolder'],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['id'] as String;
    } else {
      throw Exception('Failed to create backup file in Google Drive');
    }
  }

  /// Backup local databases to Google Drive
  Future<bool> backup() async {
    if (_currentUser == null) {
      final signedIn = await signIn();
      if (!signedIn) return false;
    }

    try {
      final headers = await _currentUser!.authHeaders;
      final fileId =
          await _findBackupFileId(headers) ?? await _createBackupFile(headers);

      final backupJson = await _dataSerializationService.exportDataToJson();
      final patchUrl = Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media',
      );

      final response = await _httpClient.patch(
        patchUrl,
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: backupJson,
      );

      return response.statusCode == 200;
    } catch (e, st) {
      debugPrint('GoogleDriveBackupService.backup error: $e\n$st');
      return false;
    }
  }

  /// Restore databases from Google Drive backup.
  Future<bool> restore() async {
    if (_currentUser == null) {
      final signedIn = await signIn();
      if (!signedIn) return false;
    }

    try {
      final headers = await _currentUser!.authHeaders;
      final fileId = await _findBackupFileId(headers);
      if (fileId == null) return false;

      final downloadUrl = Uri.parse(
        'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
      );
      final response = await _httpClient.get(downloadUrl, headers: headers);
      if (response.statusCode != 200) return false;

      // `response.body` DEĞİL: package:http, Content-Type'ta charset yoksa
      // yalnız `application/json` için utf8'e düşer, başka her değerde
      // latin1'e. Yedek her zaman utf8 yazıldığından burada da utf8 okunur.
      // Latin1 çözme hata vermez — sessizce mojibake üretir ve JSON yine
      // parse olurdu, yani tüm Türkçe karakterler fark edilmeden bozulurdu.
      final restoreResult = await _dataSerializationService
          .importDataFromJson(utf8.decode(response.bodyBytes));
      return restoreResult.isSuccess;
    } catch (e, st) {
      debugPrint('GoogleDriveBackupService.restore error: $e\n$st');
      return false;
    }
  }
}
