import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/enums/notification_frequency.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/notifications/notification_diagnostics.dart';
import 'package:cunehat/features/settings/presentation/bloc/notification_settings/notification_settings_bloc.dart';
import 'package:cunehat/features/settings/presentation/bloc/notification_settings/notification_settings_event.dart';
import 'package:cunehat/features/settings/presentation/bloc/notification_settings/notification_settings_state.dart';
import 'package:cunehat/features/settings/presentation/widgets/notification_settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class MockNotificationSettingsBloc
    extends MockBloc<NotificationSettingsEvent, NotificationSettingsState>
    implements NotificationSettingsBloc {}

/// Test bildirimi başarısız olduğunda kullanıcı TEK bir "Test bildirimi
/// gönderilemedi" cümlesi görüyordu. Sebep bilinmeden yapılabilecek hiçbir şey
/// yok: izin kapalıysa ayarlara gitmek, kanal susturulmuşsa o türü açmak,
/// platform hatasıysa metni iletmek gerekiyor. Bu mantığın (kartın
/// `listener`'ı) hiç widget testi yoktu.
void main() {
  late MockNotificationSettingsBloc bloc;

  setUp(() => bloc = MockNotificationSettingsBloc());

  Widget host() => BlocProvider<NotificationSettingsBloc>.value(
        value: bloc,
        child: MaterialApp(
          scaffoldMessengerKey: appMessengerKey,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: const Scaffold(
            body: SingleChildScrollView(child: NotificationSettingsCard()),
          ),
        ),
      );

  /// Kart yalnız `testNotificationSentAt` DEĞİŞİNCE mesaj gösterir; bu yüzden
  /// önce sonuçsuz bir durum, sonra sonucu olan bir durum yayınlıyoruz.
  Future<void> emitResult(
    WidgetTester tester,
    NotificationSettingsState result,
  ) async {
    whenListen(
      bloc,
      Stream<NotificationSettingsState>.fromIterable([result]),
      initialState: const NotificationSettingsState(),
    );
    await tester.pumpWidget(host());
    await tester.pump();
    await tester.pump();
  }

  testWidgets('izin kapalıysa izin metnini gösterir', (tester) async {
    await emitResult(
      tester,
      NotificationSettingsState(
        systemPermissionGranted: false,
        testNotificationSentAt: DateTime(2026, 9, 10),
        testNotificationFailure: NotificationFailure.noAppPermission,
      ),
    );

    expect(find.textContaining('bildirim izni kapalı'), findsOneWidget);
  });

  testWidgets('kanal susturulmuşsa KANAL ADINI söyler', (tester) async {
    await emitResult(
      tester,
      NotificationSettingsState(
        testNotificationSentAt: DateTime(2026, 9, 10),
        testNotificationFailure: NotificationFailure.channelBlocked,
        testNotificationDetail: 'Kritik Hatırlatmalar',
      ),
    );

    // Kullanıcı hangi türü açacağını bilmeden sistem ayarlarında kaybolur.
    expect(find.textContaining('Kritik Hatırlatmalar'), findsOneWidget);
  });

  testWidgets('platform hatasında istisna metnini gösterir', (tester) async {
    await emitResult(
      tester,
      NotificationSettingsState(
        testNotificationSentAt: DateTime(2026, 9, 10),
        testNotificationFailure: NotificationFailure.platformError,
        testNotificationDetail: 'PlatformException(bad icon)',
      ),
    );

    // Release'te debugPrint hiçbir yere gitmiyor; ekrana yazmazsak ayrıntı
    // tamamen kaybolur.
    expect(find.textContaining('PlatformException(bad icon)'), findsOneWidget);
  });

  testWidgets('sisteme iletilip gösterilmediyse pil/kısıtlama metni çıkar',
      (tester) async {
    await emitResult(
      tester,
      NotificationSettingsState(
        testNotificationSentAt: DateTime(2026, 9, 10),
        testNotificationFailure: NotificationFailure.notDelivered,
      ),
    );

    expect(find.textContaining('Pil optimizasyonu'), findsOneWidget);
  });

  testWidgets('teslim edildiyse başarı metni çıkar', (tester) async {
    await emitResult(
      tester,
      NotificationSettingsState(
        testNotificationSentAt: DateTime(2026, 9, 10),
        testNotificationDelivered: true,
      ),
    );

    expect(find.text('Test bildirimi gönderildi'), findsOneWidget);
  });

  testWidgets('sıklık seçiliyken hatırlatma SAATLERİ yazılır', (tester) async {
    // "Çok (Günde 3)" ne zaman geleceğini söylemiyordu; saatler ekranda
    // durmayınca kullanıcı bildirimin hiç gelmediğini sanıyor.
    whenListen(
      bloc,
      const Stream<NotificationSettingsState>.empty(),
      initialState: const NotificationSettingsState(
        randomRemindersFrequency: NotificationFrequency.high,
      ),
    );

    await tester.pumpWidget(host());
    await tester.pump();

    for (final slot in NotificationFrequency.high.dailySlots) {
      final text = '${slot.hour.toString().padLeft(2, '0')}:'
          '${slot.minute.toString().padLeft(2, '0')}';
      expect(find.textContaining(text), findsOneWidget);
    }
  });

  testWidgets('tanılama satırı release derlemesinde de durur', (tester) async {
    whenListen(
      bloc,
      const Stream<NotificationSettingsState>.empty(),
      initialState: const NotificationSettingsState(),
    );

    await tester.pumpWidget(host());
    await tester.pump();

    // Play'den kurulmuş uygulamada "neden gelmiyor" sorusunun tek cevabı bu
    // sayfa; kDebugMode'a saklanırsa hiçbir işe yaramaz.
    expect(find.text('Bildirim tanılama'), findsOneWidget);
  });
}
