import 'package:cunehat/core/services/recent_categories_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late RecentCategoriesService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = RecentCategoriesService(await SharedPreferences.getInstance());
  });

  test('boş başlar', () {
    expect(service.ids(true), isEmpty);
    expect(service.ids(false), isEmpty);
  });

  test('en son kullanılan başa gelir', () async {
    await service.remember('a', true);
    await service.remember('b', true);
    await service.remember('c', true);

    expect(service.ids(true), ['c', 'b', 'a']);
  });

  // Kopyalamak yerine TAŞIMAK: sık kullanılan tek bir kategori aksi halde
  // şeridi kendi kopyalarıyla doldurur ve diğerlerini tavandan atardı.
  test('var olan kimlik kopyalanmaz, başa TAŞINIR', () async {
    await service.remember('a', true);
    await service.remember('b', true);
    await service.remember('a', true);

    expect(service.ids(true), ['a', 'b']);
  });

  test('tavan aşılınca en eski düşer', () async {
    for (var i = 0; i < RecentCategoriesService.maxEntries + 3; i++) {
      await service.remember('id$i', true);
    }

    final ids = service.ids(true);
    expect(ids, hasLength(RecentCategoriesService.maxEntries));
    expect(ids.first, 'id${RecentCategoriesService.maxEntries + 2}');
    expect(ids, isNot(contains('id0')));
  });

  // Seçici tek seferde tek tür gösteriyor; karışık liste kullanıcıya o an
  // seçemeyeceği çipler gösterirdi.
  test('gelir ve gider listeleri birbirine karışmaz', () async {
    await service.remember('gider-1', true);
    await service.remember('gelir-1', false);

    expect(service.ids(true), ['gider-1']);
    expect(service.ids(false), ['gelir-1']);
  });
}
