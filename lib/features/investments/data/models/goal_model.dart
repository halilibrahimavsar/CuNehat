import 'dart:ui';

import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:hive/hive.dart';

part 'goal_model.g.dart';

/// Birikim hedefi kaydı. Kurallar [GoalEntity]'de.
///
/// typeId 16: 0-2, 4-7, 9-15 kullanımda (3 ve 8 geçmişte kullanılmış
/// olabileceği için atlandı), 200 renk adapteri.
/// `HiveObject`'ten TÜREMEZ (bkz. [CategoryModel] — aynı tercih).
@HiveType(typeId: 16)
class GoalModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String walletId;

  @HiveField(3)
  final String name;

  @HiveField(4)
  final double targetAmount;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final Color color;

  @HiveField(7)
  final DateTime createdAt;

  const GoalModel({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.name,
    required this.targetAmount,
    required this.category,
    required this.color,
    required this.createdAt,
  });

  GoalEntity toEntity() => GoalEntity(
        id: id,
        userId: userId,
        walletId: walletId,
        name: name,
        targetAmount: targetAmount,
        category: category,
        color: color,
        createdAt: createdAt,
      );

  factory GoalModel.fromEntity(GoalEntity e) => GoalModel(
        id: e.id,
        userId: e.userId,
        walletId: e.walletId,
        name: e.name,
        targetAmount: e.targetAmount,
        category: e.category,
        color: e.color,
        createdAt: e.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'walletId': walletId,
        'name': name,
        'targetAmount': targetAmount,
        'category': category,
        'color': color.toARGB32(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        walletId: json['walletId'] as String,
        name: json['name'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        category: json['category'] as String,
        color: Color(json['color'] as int),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'GoalModel($id, $name, target: $targetAmount)';
}
