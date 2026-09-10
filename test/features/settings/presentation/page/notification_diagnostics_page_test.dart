import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/notifications/notification_constants.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/features/settings/presentation/page/notification_diagnostics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationService extends Mock implements NotificationService {}

/// Release derlemesinde bildirim boru hattındaki her hata `debugPrint` ile
/// yutuluyordu ve `debugPrint` release'te hiçbir yere gitmez: Play'den kurulmuş
/// bir uygulamada "neden bildirim gelmiyor" sorusunun cevabı YOKTU. Bu sayfa o
/// cevabı veriyor; testler cevabın gerçekten okunabilir olduğunu sabitliyor.
void main() {
  late MockNotificationService service;

  NotificationDiagnostics diagnostics({
    bool appLevelEnabled = true,
    bool canScheduleExactAlarms = false,
    String localTimeZone = 'Europe/Istanbul',
    int pendingCount = 3,
    DateTime? nextScheduledAt,
    String? lastError,
    bool motivationalBlocked = false,
  }) =>
      NotificationDiagnostics(
        appLevelEnabled: appLevelEnabled,
        canRequestPermission: true,
        canScheduleExactAlarms: canScheduleExactAlarms,
        localTimeZone: localTimeZone,
        pendingCount: pendingCount,
        nextScheduledAt: nextScheduledAt,
        lastError: lastError,
        channels: [
          const NotificationChannelStatus(
            kind: NotificationChannelKind.critical,
            id: 'cunehat_critical',
            name: 'Kritik Hatırlatmalar',
            blocked: false,
          ),
          NotificationChannelStatus(
            kind: NotificationChannelKind.motivational,
            id: 'cunehat_motivational',
            name: 'Motivasyon',
            blocked: motivationalBlocked,
          ),
        ],
      );

  setUp(() {
    getIt.allowReassignment = true;
    service = MockNotificationService();
    getIt.registerSingleton<NotificationService>(service);
  });

  tearDown(getIt.reset);

  Future<void> open(WidgetTester tester, NotificationDiagnostics data) async {
    when(service.readDiagnostics).thenAnswer((_) async => data);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: const NotificationDiagnosticsPage(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('planlanmış hatırlatma sayısını gösterir', (tester) async {
    await open(tester, diagnostics(pendingCount: 3));

    expect(find.text('3 adet'), findsOneWidget);
  });

  testWidgets(
      'SIFIR bekleyen açıkça söylenir — "ayar açık ama bildirim yok" '
      'şikâyetinin en hızlı ayrımı', (tester) async {
    await open(tester, diagnostics(pendingCount: 0));

    expect(
        find.textContaining('hiçbir hatırlatma kurulu değil'), findsOneWidget);
  });

  testWidgets('susturulmuş kanal listede kapalı görünür', (tester) async {
    await open(tester, diagnostics(motivationalBlocked: true));

    expect(find.text('Motivasyon'), findsOneWidget);
    // Uygulama izni AÇIK olduğu halde bu kanaldan bildirim gitmez; ikisi
    // karıştırılırsa kullanıcı yanlış ayara gönderilir.
    expect(find.text('Kapalı'), findsWidgets);
  });

  testWidgets('saat dilimi UTC ise uyarı gösterilir', (tester) async {
    await open(tester, diagnostics(localTimeZone: 'UTC'));

    expect(find.textContaining('Saat dilimi okunamadı'), findsOneWidget);
  });

  testWidgets('saat dilimi okunduysa uyarı YOK', (tester) async {
    await open(tester, diagnostics(localTimeZone: 'Europe/Istanbul'));

    expect(find.text('Europe/Istanbul'), findsOneWidget);
    expect(find.textContaining('Saat dilimi okunamadı'), findsNothing);
  });

  testWidgets('tam alarm izni kapalıyken bunun BEKLENEN olduğu anlatılır',
      (tester) async {
    await open(tester, diagnostics(canScheduleExactAlarms: false));

    // SCHEDULE_EXACT_ALARM bilerek istenmiyor (Play politikası); kullanıcı
    // bunu bir arıza sanmamalı.
    expect(find.textContaining('dakikasında değil'), findsOneWidget);
  });

  testWidgets('son hata ekranda yazılır', (tester) async {
    await open(tester, diagnostics(lastError: 'show(1): PlatformException'));

    expect(find.textContaining('show(1): PlatformException'), findsOneWidget);
  });

  testWidgets('hata yoksa "Yok" der', (tester) async {
    await open(tester, diagnostics());

    expect(find.text('Yok'), findsOneWidget);
  });

  testWidgets('izin kapalıyken sistem ayarları kısayolu çıkar', (tester) async {
    when(service.openSystemNotificationSettings).thenAnswer((_) async => true);
    await open(tester, diagnostics(appLevelEnabled: false));

    final button = find.widgetWithText(TextButton, 'Ayarları Aç');
    expect(button, findsWidgets);

    await tester.tap(button.first);
    await tester.pump();
    verify(service.openSystemNotificationSettings).called(1);
  });

  testWidgets('yenile düğmesi tanılamayı yeniden okur', (tester) async {
    await open(tester, diagnostics());

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    // Bayat bir tanılama, tanılama olmamasından kötüdür.
    verify(service.readDiagnostics).called(2);
  });
}
