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
}
