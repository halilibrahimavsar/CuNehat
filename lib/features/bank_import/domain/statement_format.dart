/// İçe aktarılan banka ekstresinin dosya biçimi.
enum StatementFormat {
  csv,
  excel,
  pdf;

  /// file_picker için izinli uzantılar.
  List<String> get extensions => switch (this) {
        StatementFormat.csv => const ['csv', 'txt'],
        StatementFormat.excel => const ['xlsx'],
        StatementFormat.pdf => const ['pdf'],
      };

  /// Format seçimi kullanıcıya sorulmadan tek dosya seçicide birlikte
  /// sunulacak uzantıların birleşimi (bkz. [fromExtension]).
  static List<String> get allExtensions => [
        for (final f in StatementFormat.values) ...f.extensions,
      ];

  static StatementFormat? fromExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1) return null;
    final ext = path.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'csv' || 'txt' => StatementFormat.csv,
      'xlsx' => StatementFormat.excel,
      'pdf' => StatementFormat.pdf,
      _ => null,
    };
  }
}
