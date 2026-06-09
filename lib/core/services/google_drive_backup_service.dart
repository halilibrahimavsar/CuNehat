import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';

/// Kasıtlı cross-feature servis: yedekleme tüm feature'ların Hive
/// modellerini serileştirmek zorunda; somut model bağımlılıkları v1 için
/// bilinçli kabul (soyut arayüz post-1.0 notu).
@lazySingleton
class GoogleDriveBackupService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

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

  /// Search for cunehat_backup.json in the AppData folder of user's Google Drive.
  /// Returns the file ID if found, otherwise null.
  Future<String?> _findBackupFileId(Map<String, String> headers) async {
    final url = Uri.parse(
      'https://www.googleapis.com/drive/v3/files?spaces=appDataFolder&q=name=%27cunehat_backup.json%27%20and%20trashed=false',
    );
    final response = await http.get(url, headers: headers);

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
    final response = await http.post(
      url,
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': 'cunehat_backup.json',
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

  /// Serialize all local Hive databases to a single JSON string
  Future<String> _serializeDatabase() async {
    final walletBox = await Hive.openBox<WalletModel>('wallets');
    final transactionBox = await Hive.openBox<TransactionModel>('transactions');
    final investmentBox =
        await Hive.openBox<InvestmentModel>('investments_box');
    final debtBox = await Hive.openBox<DebtModel>('debts');
    final receivableBox = await Hive.openBox<ReceivableModel>('receivables');
    final userBox = await Hive.openBox<Map>('users');

    final wallets = walletBox.values.map((w) => w.toJson()).toList();
    final transactions = transactionBox.values.map((t) => t.toJson()).toList();
    final investments = investmentBox.values.map((i) => i.toJson()).toList();
    final debts = debtBox.values.map((d) => d.toJson()).toList();
    final receivables = receivableBox.values.map((r) => r.toJson()).toList();

    final users = <String, Map>{};
    for (final key in userBox.keys) {
      final value = userBox.get(key);
      if (value != null) {
        users[key.toString()] = Map<String, dynamic>.from(value);
      }
    }

    final backupMap = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'wallets': wallets,
      'transactions': transactions,
      'investments': investments,
      'debts': debts,
      'receivables': receivables,
      'users': users,
    };

    return jsonEncode(backupMap);
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

      final backupJson = await _serializeDatabase();
      final patchUrl = Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media',
      );

      final response = await http.patch(
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
  ///
  /// Atomik: önce uzak yedek indirilip TÜM modeller parse edilir (bu aşamada
  /// yerel veriye dokunulmaz). Ardından mevcut yerel veri bellekte snapshot'lanır,
  /// kutular temizlenip yeni veri yazılır. Yazma sırasında herhangi bir hata olursa
  /// snapshot'tan geri dönülerek kısmi veri kaybı önlenir.
  Future<bool> restore() async {
    if (_currentUser == null) {
      final signedIn = await signIn();
      if (!signedIn) return false;
    }

    // Önce indir ve tüm modelleri parse et — yerel veriye henüz dokunma.
    final List<WalletModel> wallets;
    final List<TransactionModel> transactions;
    final List<InvestmentModel> investments;
    final List<DebtModel> debts;
    final List<ReceivableModel> receivables;
    final Map<String, Map> users;
    try {
      final headers = await _currentUser!.authHeaders;
      final fileId = await _findBackupFileId(headers);
      if (fileId == null) return false;

      final downloadUrl = Uri.parse(
        'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
      );
      final response = await http.get(downloadUrl, headers: headers);
      if (response.statusCode != 200) return false;

      final backupData = jsonDecode(response.body) as Map<String, dynamic>;

      wallets = (backupData['wallets'] as List<dynamic>? ?? []).map((w) {
        final data = Map<String, dynamic>.from(w as Map);
        return WalletModel.fromJson(data['id'] as String, data);
      }).toList();

      transactions =
          (backupData['transactions'] as List<dynamic>? ?? []).map((t) {
        final data = Map<String, dynamic>.from(t as Map);
        return TransactionModel.fromJson(data['id'] as String, data);
      }).toList();

      investments =
          (backupData['investments'] as List<dynamic>? ?? []).map((i) {
        final data = Map<String, dynamic>.from(i as Map);
        return InvestmentModel.fromJson(data['id'] as String, data);
      }).toList();

      debts = (backupData['debts'] as List<dynamic>? ?? [])
          .map((d) => DebtModel.fromJson(Map<String, dynamic>.from(d as Map)))
          .toList();

      receivables = (backupData['receivables'] as List<dynamic>? ?? [])
          .map((r) =>
              ReceivableModel.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();

      users = <String, Map>{};
      final usersMap = backupData['users'] as Map<String, dynamic>? ?? {};
      for (final entry in usersMap.entries) {
        users[entry.key] = Map<dynamic, dynamic>.from(entry.value as Map);
      }
    } catch (e, st) {
      debugPrint('GoogleDriveBackupService.restore download/parse error: $e\n$st');
      return false;
    }

    // Kutuları aç ve mevcut veriyi bellekte snapshot'la (rollback için).
    final walletBox = await Hive.openBox<WalletModel>('wallets');
    final transactionBox = await Hive.openBox<TransactionModel>('transactions');
    final investmentBox =
        await Hive.openBox<InvestmentModel>('investments_box');
    final debtBox = await Hive.openBox<DebtModel>('debts');
    final receivableBox = await Hive.openBox<ReceivableModel>('receivables');
    final userBox = await Hive.openBox<Map>('users');

    final walletSnapshot = Map.of(walletBox.toMap());
    final transactionSnapshot = Map.of(transactionBox.toMap());
    final investmentSnapshot = Map.of(investmentBox.toMap());
    final debtSnapshot = Map.of(debtBox.toMap());
    final receivableSnapshot = Map.of(receivableBox.toMap());
    final userSnapshot = Map.of(userBox.toMap());

    try {
      await walletBox.clear();
      await transactionBox.clear();
      await investmentBox.clear();
      await debtBox.clear();
      await receivableBox.clear();
      await userBox.clear();

      for (final model in wallets) {
        await walletBox.put(model.id, model);
      }
      for (final model in transactions) {
        await transactionBox.put(model.id, model);
      }
      for (final model in investments) {
        await investmentBox.put(model.id, model);
      }
      for (final model in debts) {
        await debtBox.put(model.id, model);
      }
      for (final model in receivables) {
        await receivableBox.put(model.id, model);
      }
      for (final entry in users.entries) {
        await userBox.put(entry.key, entry.value);
      }

      return true;
    } catch (e, st) {
      debugPrint('GoogleDriveBackupService.restore write error: $e\n$st');
      // Rollback: snapshot'tan eski veriyi geri yükle.
      try {
        await _rollback(walletBox, walletSnapshot);
        await _rollback(transactionBox, transactionSnapshot);
        await _rollback(investmentBox, investmentSnapshot);
        await _rollback(debtBox, debtSnapshot);
        await _rollback(receivableBox, receivableSnapshot);
        await _rollback(userBox, userSnapshot);
      } catch (rollbackError, rollbackSt) {
        debugPrint(
            'GoogleDriveBackupService.restore rollback FAILED: $rollbackError\n$rollbackSt');
      }
      return false;
    }
  }

  /// Bir kutuyu temizleyip snapshot'taki içerikle yeniden doldurur.
  Future<void> _rollback(Box box, Map snapshot) async {
    await box.clear();
    await box.putAll(snapshot);
  }
}
