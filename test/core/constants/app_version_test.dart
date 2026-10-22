import 'dart:io';

import 'package:cunehat/core/constants/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bekçi test: ekranda yazan sürüm, pubspec'teki sürümle aynı olmalı.
void main() {
  test('kAppVersionName pubspec.yaml sürüm adıyla aynı', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)', multiLine: true)
            .firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml içinde version: yok');
    expect(
      kAppVersionName,
      match!.group(1),
      reason: 'Sürüm yükseltildi ama lib/core/constants/app_version.dart '
          'güncellenmedi; çekmece eski sürümü gösterirdi.',
    );
  });

  // Hakkında kartı sabiti değil elle yazılmış '1.0.0'ı gösteriyordu: 1.1.0
  // kullanıcısı ekranda 1.0.0 görüyordu. Sürüm yalnız sabitten okunur.
  test('lib/ içinde elle yazılmış sürüm metni yok', () {
    final literal = RegExp(r'''['"]v?\d+\.\d+\.\d+['"]''');
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.endsWith('app_version.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        if (literal.hasMatch(lines[i])) offenders.add('$path:${i + 1}');
      }
    }
    expect(offenders, isEmpty, reason: 'Sürüm kAppVersionName ile yazılmalı.');
  });
}
