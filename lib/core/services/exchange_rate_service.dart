import 'dart:convert';

import 'package:cunehat/core/utils/tr_price_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// USD/EUR → TL kuru: canlı (truncgil 'Satış') + önbellek.
///
/// Sözleşme: ASLA fırlatmaz. Sıra: taze bellek önbelleği (TTL içinde) → ağ →
/// bayat prefs önbelleği (yaşına bakılmaz; çevrimdışı senaryo). Hiçbiri yoksa
/// `null` — çağıran gösterimi gizler ya da kendi hatasını üretir
/// (yatırım tarafı ServerException'a çevirir).
///
/// Kurlar kod-başına bağımsızdır: API yanıtında tek kur eksikse diğeri yine
/// kullanılır ve eksik olanın son bilinen değeri korunur (merge). Tek ağ
/// çağrısı tüm kurları getirir; eşzamanlı istekler aynı isteği paylaşır.
@lazySingleton
class ExchangeRateService {
  final http.Client client;
  final SharedPreferences prefs;

  ExchangeRateService({required this.client, required this.prefs});

  static const _url = 'https://finans.truncgil.com/today.json';
  static const _cacheKey = 'exchange_rates_cache_v1';
  static const _ttl = Duration(hours: 1);
  static const _supported = ['USD', 'EUR'];

  /// Kur isteğinin üst sınırı. `http` paketinin varsayılan yanıt zaman aşımı
  /// YOKTUR: captive portal ya da paket düşüren bir şebekede istek TCP'nin
  /// OS zaman aşımına (dakikalar) kadar asılı kalır. Bu Future'ı bekleyen
  /// ekranlar (transfer sheet) o süre boyunca kilitlenirdi.
  static const requestTimeout = Duration(seconds: 15);

  Map<String, double>? _memRates;
  DateTime? _memAt;
  Future<Map<String, double>?>? _inflight;

  /// 1 birim [code] için TL kuru. TRY → 1.0; desteklenmeyen kod → null.
  Future<double?> rateToTry(String code) async {
    final c = code.toUpperCase();
    if (c == 'TRY') return 1.0;
    if (!_supported.contains(c)) return null;

    if (_isMemFresh && _memRates!.containsKey(c)) return _memRates![c];

    final fetched = await (_inflight ??= _fetchAndCache());
    _inflight = null;
    final fresh = fetched?[c];
    if (fresh != null) return fresh;

    // Ağ yok/başarısız ya da bu kod yanıtta eksik: son bilinen kur.
    return _readPrefsRates()?[c];
  }

  /// Ağa çıkmadan, yalnız bellek/prefs önbelleğinden (senkron gösterimler
  /// için; ör. cüzdan kartındaki "≈ ₺" satırı). TRY → 1.0.
  double? cachedRateToTry(String code) {
    final c = code.toUpperCase();
    if (c == 'TRY') return 1.0;
    if (!_supported.contains(c)) return null;
    if (_memRates?.containsKey(c) ?? false) return _memRates![c];
    // Prefs'ten belleğe al; _memAt YAZILMAZ ki bayat set TTL tazeliği
    // kazanmasın ve ilk rateToTry ağdan yenilesin.
    final stored = _readPrefsRates();
    if (stored != null) _memRates = {...?_memRates, ...stored};
    return stored?[c];
  }

  bool get _isMemFresh =>
      _memRates != null &&
      _memAt != null &&
      DateTime.now().difference(_memAt!) < _ttl;

  Future<Map<String, double>?> _fetchAndCache() async {
    try {
      final response =
          await client.get(Uri.parse(_url)).timeout(requestTimeout);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final fetched = <String, double>{};
      for (final code in _supported) {
        final entry = data[code];
        final rate = parseTrPrice(entry is Map ? entry['Satış'] : null);
        if (rate != null && rate > 0) fetched[code] = rate;
      }
      if (fetched.isEmpty) return null;

      // Eksik kodların son bilinen değeri silinmesin: eskiyle birleştir.
      final merged = {...?_readPrefsRates(), ...fetched};
      _memRates = merged;
      _memAt = DateTime.now();
      await prefs.setString(
        _cacheKey,
        json.encode({
          'rates': merged,
          'ts': _memAt!.toIso8601String(),
        }),
      );
      return merged;
    } catch (e) {
      debugPrint('ExchangeRateService: kur alınamadı: $e');
      return null;
    }
  }

  Map<String, double>? _readPrefsRates() {
    try {
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final rawRates = decoded['rates'] as Map<String, dynamic>;
      return {
        for (final e in rawRates.entries) e.key: (e.value as num).toDouble(),
      };
    } catch (e) {
      debugPrint('ExchangeRateService: önbellek okunamadı: $e');
      return null;
    }
  }
}
