import 'dart:io';

import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/features/investments/data/datasource/goal_local_datasource.dart';
import 'package:cunehat/features/investments/data/models/goal_model.dart';
import 'package:cunehat/features/investments/presentation/widgets/color_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockHiveInterface extends Mock implements HiveInterface {}

/// Hedeflerin kalıcı deposu — bu dosyaya kadar HİÇ testi yoktu, oysa
/// diğer her kutunun (cüzdan, işlem, borç, alacak, bütçe, yatırım, düzenli)
/// datasource testi var.
///
/// En kritik davranış CÜZDAN KAPSAMIDIR: hedefler yatırımlar gibi cüzdan
/// bazlıdır ve süzgeç kaçarsa başka cüzdanın hedefi listeye girer.
void main() {
  late Directory dir;
  late GoalLocalDataSource dataSource;

  GoalModel goal({
    String id = 'g1',
    String userId = 'u1',
    String walletId = 'w1',
    double target = 1000,
  }) =>
      GoalModel(
        id: id,
        userId: userId,
        walletId: walletId,
        name: 'Hedef $id',
        targetAmount: target,
        category: 'genel',
        color: const Color(0xFF2196F3),
        createdAt: DateTime(2026, 8, 24),
      );

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('cunehat_goal_ds');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(200)) Hive.registerAdapter(ColorAdapter());
    if (!Hive.isAdapterRegistered(16)) Hive.registerAdapter(GoalModelAdapter());
  });

  setUp(() async {
    dataSource = GoalLocalDataSource(Hive);
    if (Hive.isBoxOpen(GoalLocalDataSource.boxName)) {
      await Hive.box<GoalModel>(GoalLocalDataSource.boxName).clear();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  group('cüzdan kapsamı', () {
    test('yalnız AYNI kullanıcı + AYNI cüzdanın hedefleri döner', () async {
      await dataSource.put(goal(id: 'g1'));
      await dataSource.put(goal(id: 'g2', walletId: 'w2'));
      await dataSource.put(goal(id: 'g3', userId: 'u2'));

      final result = await dataSource.getGoals(userId: 'u1', walletId: 'w1');

      expect(result.map((g) => g.id), ['g1']);
    });

    test('hiç eşleşme yoksa BOŞ liste döner (hata değil)', () async {
      await dataSource.put(goal(id: 'g1'));

      expect(await dataSource.getGoals(userId: 'u1', walletId: 'yok'), isEmpty);
    });
  });

  group('yazma ve silme', () {
    test('put aynı kimlikle ÜZERİNE yazar (kopya üretmez)', () async {
      await dataSource.put(goal(target: 1000));
      await dataSource.put(goal(target: 2000));

      final result = await dataSource.getGoals(userId: 'u1', walletId: 'w1');

      expect(result, hasLength(1));
      expect(result.single.targetAmount, 2000);
    });

    test('delete yalnız hedeflenen kaydı siler', () async {
      await dataSource.put(goal(id: 'g1'));
      await dataSource.put(goal(id: 'g2'));

      await dataSource.delete('g1');

      final result = await dataSource.getGoals(userId: 'u1', walletId: 'w1');
      expect(result.map((g) => g.id), ['g2']);
    });

    test('olmayan kimliği silmek sessizce geçer', () async {
      await dataSource.put(goal(id: 'g1'));
      await dataSource.delete('yok');
      expect(await dataSource.getGoals(userId: 'u1', walletId: 'w1'),
          hasLength(1));
    });

    test('deleteForWallet YALNIZ o cüzdanın hedeflerini siler', () async {
      // Cüzdan silinince hedefleri de gider; öksüz hedef ilerleme hesabında
      // bölen olarak kalırdı.
      await dataSource.put(goal(id: 'g1'));
      await dataSource.put(goal(id: 'g2'));
      await dataSource.put(goal(id: 'g3', walletId: 'w2'));

      await dataSource.deleteForWallet('w1');

      expect(await dataSource.getGoals(userId: 'u1', walletId: 'w1'), isEmpty);
      expect(await dataSource.getGoals(userId: 'u1', walletId: 'w2'),
          hasLength(1));
    });

    test('deleteForWallet KULLANICIYA bakmaz — cüzdan zaten tek kullanıcının',
        () async {
      await dataSource.put(goal(id: 'g1', userId: 'u1'));
      await dataSource.put(goal(id: 'g2', userId: 'u2'));

      await dataSource.deleteForWallet('w1');

      expect(await dataSource.getGoals(userId: 'u2', walletId: 'w1'), isEmpty);
    });
  });

  group('hata yolu CacheException e çevrilir', () {
    late MockHiveInterface hive;
    late GoalLocalDataSource failing;

    setUp(() {
      hive = MockHiveInterface();
      when(() => hive.isBoxOpen(any())).thenReturn(false);
      when(() => hive.openBox<GoalModel>(any()))
          .thenThrow(Exception('disk yok'));
      failing = GoalLocalDataSource(hive);
    });

    test('getGoals', () {
      expect(() => failing.getGoals(userId: 'u1', walletId: 'w1'),
          throwsA(isA<CacheException>()));
    });

    test('put', () {
      expect(() => failing.put(goal()), throwsA(isA<CacheException>()));
    });

    test('delete', () {
      expect(() => failing.delete('g1'), throwsA(isA<CacheException>()));
    });

    test('deleteForWallet', () {
      expect(
          () => failing.deleteForWallet('w1'), throwsA(isA<CacheException>()));
    });
  });
}
