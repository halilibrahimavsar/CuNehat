import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Yakalanmış tek bir hata.
@immutable
class ErrorLogEntry {
  final DateTime at;

  /// Hatanın geldiği kanal: `FlutterError`, `Bloc BankImportCubit`,
  /// `Bildirim · schedule(12)` …
  final String source;

  /// Hatanın çalışma zamanı tipi (`StateError`, `PlatformException` …).
  final String type;

  final String message;
  final String? stack;

  /// Aynı hata ardışık kaç kez geldi. Her karede patlayan bir build hatası
  /// tamponu doldurmasın diye ardışık tekrarlar tek satırda sayılır.
  final int repeat;

  const ErrorLogEntry({
    required this.at,
    required this.source,
    required this.type,
    required this.message,
    this.stack,
    this.repeat = 1,
  });

  bool _sameIncident(ErrorLogEntry other) =>
      source == other.source && type == other.type && message == other.message;

  ErrorLogEntry _repeatedAt(DateTime when) => ErrorLogEntry(
        at: when,
        source: source,
        type: type,
        message: message,
        stack: stack,
        repeat: repeat + 1,
      );

  Map<String, Object?> toJson() => {
        'at': at.toIso8601String(),
        'source': source,
        'type': type,
        'message': message,
        if (stack != null) 'stack': stack,
        'repeat': repeat,
      };

  /// Kalıcı kayıttan okur; beklenen biçimde olmayan kayıt `null` döner.
  ///
  /// Bu tanı verisidir, kullanıcı verisi değil: tek bozuk satır yüzünden
  /// günlüğün tamamını kaybetmek, o satırı atlamaktan kötüdür.
  static ErrorLogEntry? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final at = DateTime.tryParse('${json['at']}');
    final source = json['source'];
    final type = json['type'];
    final message = json['message'];
    if (at == null ||
        source is! String ||
        type is! String ||
        message is! String) {
      return null;
    }
    final stack = json['stack'];
    final repeat = json['repeat'];
    return ErrorLogEntry(
      at: at,
      source: source,
      type: type,
      message: message,
      stack: stack is String ? stack : null,
      repeat: repeat is int && repeat > 0 ? repeat : 1,
    );
  }
}

/// Release'te de iz bırakan, cihazda kalan hata günlüğü.
///
/// Neden var: yakalanan hataların tek izi `debugPrint`ti; Play'den kurulmuş
/// bir uygulamada cihaza özgü bir hatayı (bildirim, Drive, kilit turları)
/// teşhis etmenin yolu yoktu.
///
/// Neden DI'dan bağımsız bir tekil: global hata yakalayıcılar init'ten ÖNCE
/// kuruluyor ve açılış hatası tam da DI kurulamadığı için doğabilir. Kayıtlar
/// [attach]'e kadar bellekte bekler, sonra kalıcı katmanla birleştirilir.
///
/// Gizlilik: kayıt yalnız bu cihazın `SharedPreferences`'ında durur, hiçbir
/// yere kendiliğinden gönderilmez. Paylaşım kullanıcının eylemidir.
class ErrorLog {
  ErrorLog._();

  static final ErrorLog instance = ErrorLog._();

  static const int capacity = 50;
  static const int maxMessageLength = 400;
  static const int maxStackLength = 1200;
  static const String prefsKey = 'error_log_v1';

  /// Aynı hatanın ardışık tekrarında kalıcı yazım bu kadar ertelenir: her
  /// karede patlayan bir hata her karede diske yazdırmasın.
  static const Duration repeatFlushDelay = Duration(seconds: 1);

  /// Aynı hata NESNESİ iki kanaldan gelebilir: Bloc handler'ında fırlayan
  /// hata önce `BlocObserver.onError`'a gider, sonra yeniden fırlatılıp kök
  /// zone'a düşer. Kimliği eşleşen hata ikinci kez yazılmaz.
  static const int _recentErrorsCapacity = 8;

  /// Eskiden yeniye.
  final List<ErrorLogEntry> _entries = <ErrorLogEntry>[];
  final List<Object> _recentErrors = <Object>[];

  SharedPreferences? _prefs;
  Timer? _pendingFlush;

  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  /// Yeniden eskiye.
  List<ErrorLogEntry> get entries =>
      List<ErrorLogEntry>.unmodifiable(_entries.reversed);

  /// Hatayı günlüğe ekler. ASLA fırlatmaz: hata yakalayıcıların içinden
  /// çağrılır, burada doğan bir hata yeni bir hata turu başlatırdı.
  void add(String source, Object error, [StackTrace? stack]) {
    try {
      for (final seen in _recentErrors) {
        if (identical(seen, error)) return;
      }
      _recentErrors.add(error);
      if (_recentErrors.length > _recentErrorsCapacity) {
        _recentErrors.removeAt(0);
      }

      final entry = ErrorLogEntry(
        at: clock(),
        source: source,
        type: error.runtimeType.toString(),
        message: _truncate(_describe(error), maxMessageLength),
        stack:
            stack == null ? null : _truncate(stack.toString(), maxStackLength),
      );

      if (_entries.isNotEmpty && _entries.last._sameIncident(entry)) {
        _entries[_entries.length - 1] = _entries.last._repeatedAt(entry.at);
        _scheduleFlush();
        return;
      }

      _entries.add(entry);
      final overflow = _entries.length - capacity;
      if (overflow > 0) _entries.removeRange(0, overflow);
      _flushNow();
    } catch (e) {
      debugPrint('ErrorLog: kayıt eklenemedi: $e');
    }
  }

  /// Kalıcı katmanı bağlar: önceki oturumların kayıtlarını okur ve bağlanana
  /// kadar bellekte biriken kayıtlarla (init hataları dahil) birleştirir.
  ///
  /// Aynı örnekle ikinci çağrı etkisizdir: init hata ekranındaki "Tekrar
  /// Dene" başlatmayı baştan koşar.
  void attach(SharedPreferences prefs) {
    if (identical(_prefs, prefs)) return;
    try {
      final merged = <ErrorLogEntry>[
        ..._decode(prefs.getString(prefsKey)),
        ..._entries,
      ];
      final overflow = merged.length - capacity;
      _entries
        ..clear()
        ..addAll(overflow > 0 ? merged.sublist(overflow) : merged);
    } catch (e) {
      debugPrint('ErrorLog: kalıcı günlük okunamadı: $e');
    }
    _prefs = prefs;
    _flushNow();
  }

  Future<void> clear() async {
    _entries.clear();
    _recentErrors.clear();
    _pendingFlush?.cancel();
    _pendingFlush = null;
    try {
      await _prefs?.remove(prefsKey);
    } catch (e) {
      debugPrint('ErrorLog: günlük silinemedi: $e');
    }
  }

  /// Kopyalama/paylaşım metni. Teşhise yardım etsin diye platform bilgisi
  /// eklenir; kayıtların kendisinden başka kullanıcı verisi eklenmez.
  String formatForShare() {
    final buffer = StringBuffer()
      ..writeln('ÇuNehat hata günlüğü · ${_entries.length} kayıt')
      ..writeln('Oluşturma: ${formatTimestamp(clock())}')
      ..writeln('Platform: ${_platformDescription()}');
    for (final entry in entries) {
      buffer
        ..writeln()
        ..writeln('[${formatTimestamp(entry.at)}] ${entry.source}'
            '${entry.repeat > 1 ? ' (×${entry.repeat})' : ''}')
        ..writeln('${entry.type}: ${entry.message}');
      final stack = entry.stack;
      if (stack != null && stack.isNotEmpty) buffer.writeln(stack.trimRight());
    }
    return buffer.toString();
  }

  /// Yerel ayardan bağımsız zaman damgası: günlük dilden bağımsız okunmalı
  /// ve `DateFormat` yerel verisi yüklenmeden de çalışmalı.
  static String formatTimestamp(DateTime at) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${at.year}-${two(at.month)}-${two(at.day)} '
        '${two(at.hour)}:${two(at.minute)}:${two(at.second)}';
  }

  @visibleForTesting
  void resetForTest() {
    _entries.clear();
    _recentErrors.clear();
    _pendingFlush?.cancel();
    _pendingFlush = null;
    _prefs = null;
    clock = DateTime.now;
  }

  void _scheduleFlush() {
    if (_prefs == null || _pendingFlush != null) return;
    _pendingFlush = Timer(repeatFlushDelay, () {
      _pendingFlush = null;
      _flushNow();
    });
  }

  void _flushNow() {
    final prefs = _prefs;
    if (prefs == null) return;
    _pendingFlush?.cancel();
    _pendingFlush = null;
    try {
      final payload = jsonEncode([for (final e in _entries) e.toJson()]);
      prefs.setString(prefsKey, payload).then<void>(
            (_) {},
            onError: (Object e) =>
                debugPrint('ErrorLog: günlük yazılamadı: $e'),
          );
    } catch (e) {
      debugPrint('ErrorLog: günlük yazılamadı: $e');
    }
  }

  static List<ErrorLogEntry> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) return const [];
    final result = <ErrorLogEntry>[];
    for (final item in decoded) {
      final entry = ErrorLogEntry.tryFromJson(item);
      if (entry != null) result.add(entry);
    }
    return result;
  }

  static String _describe(Object error) {
    try {
      return error.toString();
    } catch (_) {
      return '<${error.runtimeType} açıklanamadı>';
    }
  }

  static String _truncate(String value, int max) =>
      value.length <= max ? value : '${value.substring(0, max)}…';

  static String _platformDescription() {
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (_) {
      return defaultTargetPlatform.name;
    }
  }
}
