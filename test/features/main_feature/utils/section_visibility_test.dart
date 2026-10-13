import 'package:cunehat/features/main_feature/utils/section_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

void main() {
  Future<SectionVisibility> create([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    return SectionVisibility(await SharedPreferences.getInstance());
  }

  group('ilk çalıştırma', () {
    test('yeni kurulum yalnız İşlemler\'le başlar', () async {
      final sections = await create();
      await sections.ensureInitialized(existingInstall: false);

      expect(sections.enabledStates, {SliderState.transactions});
      expect(sections.hasOnlyTransactions, isTrue);
    });

    test(
        'güncellemeyle gelen kurulumda üç bölüm de açık kalır — hiçbir şey '
        'kaybolmaz', () async {
      final sections = await create();
      await sections.ensureInitialized(existingInstall: true);

      expect(sections.enabledStates, SliderState.values.toSet());
      expect(sections.hasOnlyTransactions, isFalse);
    });

    test('yalnız BİR kez uygulanır: sonraki açılış tercihi ezmez', () async {
      final sections = await create();
      await sections.ensureInitialized(existingInstall: false);
      await sections.enable(SliderState.savedMoney);

      // Bir sonraki açılış: artık "eski kurulum" (gizlilik bayrağı yazılmış).
      final prefs = await SharedPreferences.getInstance();
      final next = SectionVisibility(prefs);
      await next.ensureInitialized(existingInstall: true);

      expect(next.enabledStates,
          {SliderState.savedMoney, SliderState.transactions});
    });

    test('başlatılmadan önce de güvenli: yalnız İşlemler', () async {
      final sections = await create();
      expect(sections.enabledStates, {SliderState.transactions});
    });
  });

  group('açma / kapatma', () {
    test('açılan bölüm kalıcıdır', () async {
      final sections = await create();
      await sections.ensureInitialized(existingInstall: false);

      await sections.enable(SliderState.debt);

      final reopened = SectionVisibility(await SharedPreferences.getInstance());
      expect(reopened.debtEnabled, isTrue);
      expect(reopened.savingsEnabled, isFalse);
    });

    test('İşlemler her zaman açıktır; kapatılamaz', () async {
      final sections = await create();

      expect(sections.isEnabled(SliderState.transactions), isTrue);
      expect(
        await sections.disable(SliderState.transactions, hasRecords: false),
        isFalse,
      );
      expect(sections.isEnabled(SliderState.transactions), isTrue);
    });

    test('kaydı OLMAYAN bölüm kapatılır', () async {
      final sections = await create();
      await sections.ensureInitialized(existingInstall: true);

      final closed =
          await sections.disable(SliderState.savedMoney, hasRecords: false);

      expect(closed, isTrue);
      expect(
          sections.enabledStates, {SliderState.transactions, SliderState.debt});
    });

    test('kaydı OLAN bölüm kapatılamaz', () async {
      final sections = await create();
      await sections.ensureInitialized(existingInstall: true);

      final closed = await sections.disable(SliderState.debt, hasRecords: true);

      expect(closed, isFalse);
      expect(sections.debtEnabled, isTrue);
    });

    test('etkin küme her bileşimde bitişiktir ve İşlemler\'i içerir', () async {
      for (final (savings, debt) in [
        (false, false),
        (true, false),
        (false, true),
        (true, true),
      ]) {
        final sections = await create({
          SectionVisibility.savingsKey: savings,
          SectionVisibility.debtKey: debt,
        });
        final indices = sections.enabledStates.map((s) => s.index).toList()
          ..sort();
        expect(indices, contains(SliderState.transactions.index));
        expect(indices.last - indices.first, indices.length - 1,
            reason: 'bitişik değil: ${sections.enabledStates}');
      }
    });
  });

  group('kayıtlarla eşitleme', () {
    test('kaydı olan bölüm açılır (yedeği geri yüklenmiş yeni kurulum)',
        () async {
      final sections = await create();
      await sections.ensureInitialized(existingInstall: false);

      await sections.syncWithRecords(
        savingsHasRecords: true,
        debtHasRecords: false,
      );

      expect(sections.enabledStates,
          {SliderState.savedMoney, SliderState.transactions});
    });

    test('kaydı olmayan bölümü KAPATMAZ', () async {
      final sections = await create();
      await sections.ensureInitialized(existingInstall: true);

      await sections.syncWithRecords(
        savingsHasRecords: false,
        debtHasRecords: false,
      );

      expect(sections.enabledStates, SliderState.values.toSet());
    });
  });

  group('bildirim', () {
    test('yalnız GERÇEK değişiklikte haber verir', () async {
      final sections = await create();
      await sections.ensureInitialized(existingInstall: false);
      var notified = 0;
      sections.addListener(() => notified++);

      await sections.enable(SliderState.debt);
      await sections.enable(SliderState.debt);
      await sections.syncWithRecords(
          savingsHasRecords: false, debtHasRecords: true);

      expect(notified, 1);
    });
  });

  // Anahtarlar cihazda yazılı kalır; yeniden adlandırmak herkesin bölüm
  // tercihini sıfırlar.
  test('tercih anahtarları değişmez', () {
    expect(SectionVisibility.initializedKey, 'sections_initialized');
    expect(SectionVisibility.savingsKey, 'section_savings_enabled');
    expect(SectionVisibility.debtKey, 'section_debt_enabled');
  });
}
