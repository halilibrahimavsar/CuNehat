import 'package:cunehat/core/services/data_repair_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('planUserIdRepairs', () {
    const wallets = {'w1': 'local_user', 'w2': 'local_user'};

    test('cüzdan sahibinden farklı userId onarılır', () {
      final repairs = planUserIdRepairs(
        walletUserIds: wallets,
        records: [
          (key: 'a', userId: 'unknown_user', walletId: 'w1'),
        ],
      );
      expect(repairs.length, 1);
      expect(repairs.single.key, 'a');
      expect(repairs.single.correctUserId, 'local_user');
    });

    test('uyumlu kayda dokunulmaz', () {
      final repairs = planUserIdRepairs(
        walletUserIds: wallets,
        records: [
          (key: 'a', userId: 'local_user', walletId: 'w1'),
          (key: 'b', userId: 'local_user', walletId: 'w2'),
        ],
      );
      expect(repairs, isEmpty);
    });

    test('yetim kayıt (cüzdanı yok) atlanır', () {
      final repairs = planUserIdRepairs(
        walletUserIds: wallets,
        records: [
          (key: 'a', userId: 'unknown_user', walletId: 'silinmis-cuzdan'),
        ],
      );
      expect(repairs, isEmpty);
    });

    test('ikinci geçiş boş (idempotans)', () {
      final once = planUserIdRepairs(
        walletUserIds: wallets,
        records: [
          (key: 'a', userId: 'unknown_user', walletId: 'w1'),
        ],
      );
      // Onarım uygulanmış gibi: userId artık doğru.
      final twice = planUserIdRepairs(
        walletUserIds: wallets,
        records: [
          (key: 'a', userId: once.single.correctUserId, walletId: 'w1'),
        ],
      );
      expect(twice, isEmpty);
    });
  });
}
