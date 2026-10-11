import 'package:flutter/widgets.dart';

/// Defterde çoklu seçim durumu: seçili işlem kimlikleri.
///
/// Seçim kipi ayrı bir bayrak DEĞİL, kümenin boş olmamasıdır: son satırın
/// seçimi kalkınca kip de biter — "seçim kipinde ama hiçbir şey seçili
/// değil" diye bir ara durum yok.
///
/// Neden var: ekstre içe aktarıldıktan sonra yanlış kategoriye düşen on
/// satırı düzeltmenin tek yolu her birini tek tek açıp düzenlemekti.
class LedgerSelection extends ChangeNotifier {
  final Set<String> _ids = {};

  bool get active => _ids.isNotEmpty;
  int get count => _ids.length;
  Set<String> get ids => Set.unmodifiable(_ids);

  bool contains(String? id) => id != null && _ids.contains(id);

  void toggle(String id) {
    if (!_ids.remove(id)) _ids.add(id);
    notifyListeners();
  }

  void clear() {
    if (_ids.isEmpty) return;
    _ids.clear();
    notifyListeners();
  }
}

/// [LedgerSelection]'ı defter satırlarına indirir. Kapsamın DIŞINDAKİ
/// satırlar (detay sayfası, rapor listeleri) seçim sunmaz.
class LedgerSelectionScope extends InheritedNotifier<LedgerSelection> {
  const LedgerSelectionScope({
    super.key,
    required LedgerSelection selection,
    required super.child,
  }) : super(notifier: selection);

  static LedgerSelection? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<LedgerSelectionScope>()
      ?.notifier;
}
