import 'dart:io';

import 'package:cunehat/features/investments/data/models/goal_model.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/color_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Birikim hedefi kaydı — şema v9'un yeni kutusu (typeId 16).
///
/// Bu dosya bir BOŞLUK kapatıyor: hedeflerin kalıcılık katmanının (model,
/// datasource, repo) hiç testi yoktu, oysa `toJson`/`fromJson` yedek yolunda
/// ve `fromJson`'ın SEKİZ alanı da katı cast — biri değişirse yedek sessizce
/// değil, gürültülü ama TEST EDİLMEMİŞ biçimde kırılır.
void main() {
  final created = DateTime(2026, 8, 24, 10, 30);

  GoalModel model() => GoalModel(
        id: 'g1',
        userId: 'u1',
        walletId: 'w1',
        name: 'Ev peşinatı',
        targetAmount: 250000.0,
        category: 'house',
        color: const Color(0xFF2196F3),
        createdAt: created,
      );

  group('JSON gidiş-dönüş (yedek yolu)', () {
    test('toJson → fromJson tüm alanları korur', () {
      final back = GoalModel.fromJson(model().toJson());

      expect(back.id, 'g1');
      expect(back.userId, 'u1');
      expect(back.walletId, 'w1');
      expect(back.name, 'Ev peşinatı');
      expect(back.targetAmount, 250000.0);
      expect(back.category, 'house');
      expect(back.color.toARGB32(), const Color(0xFF2196F3).toARGB32());
      expect(back.createdAt, created);
    });

    test('renk INT olarak taşınır (JSON Color taşıyamaz)', () {
      expect(model().toJson()['color'], isA<int>());
    });

    test('tarih ISO-8601 metni olarak taşınır', () {
      expect(model().toJson()['createdAt'], created.toIso8601String());
    });

    test('eksik alan SESSİZCE varsayılana düşmez, fırlatır', () {
      // Kural: "sessiz yanlış yorumlama, gürültülü hatadan kötüdür".
      final broken = model().toJson()..remove('targetAmount');
      expect(() => GoalModel.fromJson(broken), throwsA(anything));
    });
  });

  group('entity dönüşümü', () {
    test('fromEntity → toEntity tüm alanları korur', () {
      final entity = GoalEntity(
        id: 'g1',
        userId: 'u1',
        walletId: 'w1',
        name: 'Tatil',
        targetAmount: 50000.0,
        category: 'travel',
        color: const Color(0xFF4CAF50),
        createdAt: created,
      );

      final back = GoalModel.fromEntity(entity).toEntity();

      expect(back.id, entity.id);
      expect(back.userId, entity.userId);
      expect(back.walletId, entity.walletId);
      expect(back.name, entity.name);
      expect(back.targetAmount, entity.targetAmount);
      expect(back.category, entity.category);
      expect(back.color.toARGB32(), entity.color.toARGB32());
      expect(back.createdAt, entity.createdAt);
    });
  });

  group('eşitlik KİMLİĞE dayanır', () {
    test('aynı id, farklı alanlar → eşit', () {
      final a = model();
      final b = GoalModel(
        id: 'g1',
        userId: 'baska',
        walletId: 'baska',
        name: 'Baska',
        targetAmount: 1.0,
        category: 'x',
        color: const Color(0xFFFF0000),
        createdAt: DateTime(2020),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('farklı id → eşit değil', () {
      expect(
          model() ==
              GoalModel.fromEntity(model().toEntity().copyWith(id: 'g2')),
          isFalse);
    });
  });

  group('Hive gidiş-dönüş (typeId 16)', () {
    late Directory dir;

    setUpAll(() async {
      dir = await Directory.systemTemp.createTemp('cunehat_goal_model');
      Hive.init(dir.path);
      if (!Hive.isAdapterRegistered(200)) Hive.registerAdapter(ColorAdapter());
      if (!Hive.isAdapterRegistered(16)) {
        Hive.registerAdapter(GoalModelAdapter());
      }
    });

    tearDownAll(() async {
      await Hive.close();
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('typeId 16 — yakılmış numaralarla çakışmaz', () {
      expect(GoalModelAdapter().typeId, 16);
    });

    test('diske yazılıp geri okunur', () async {
      final box = await Hive.openBox<GoalModel>('goal_model_rt');
      await box.put('g1', model());
      await box.close();

      final reopened = await Hive.openBox<GoalModel>('goal_model_rt');
      final back = reopened.get('g1')!;

      expect(back.id, 'g1');
      expect(back.name, 'Ev peşinatı');
      expect(back.targetAmount, 250000.0);
      expect(back.category, 'house');
      expect(back.color.toARGB32(), const Color(0xFF2196F3).toARGB32());
      expect(back.createdAt, created);
      expect(back.walletId, 'w1');
      expect(back.userId, 'u1');
    });
  });
}
