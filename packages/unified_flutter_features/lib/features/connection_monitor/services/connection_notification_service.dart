import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/core/texts/connection_texts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:unified_flutter_features/features/connection_monitor/connection_cubit.dart';
import 'package:unified_flutter_features/features/connection_monitor/connection_state.dart';

class ConnectionNotificationService {
  static final ConnectionNotificationService _instance =
      ConnectionNotificationService._internal();
  factory ConnectionNotificationService() => _instance;
  ConnectionNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionGranted = false;

  Future<void> initialize({bool requestPermission = false}) async {
    if (_initialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (requestPermission) {
      _permissionGranted = await _requestPermissionsIfNeeded();
    } else {
      _permissionGranted = await _areNotificationsEnabled();
    }

    _initialized = true;
  }

  Future<bool> _requestPermissionsIfNeeded() async {
    var granted = true;

    final androidNotifications =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidNotifications != null) {
      try {
        final result = await androidNotifications
            .requestNotificationsPermission()
            .timeout(const Duration(seconds: 3));
        granted = result ?? granted;
      } on TimeoutException {
        granted = false;
      } catch (_) {
        granted = false;
      }
    }

    final iosNotifications =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosNotifications != null) {
      try {
        final result = await iosNotifications.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = granted && (result ?? true);
      } catch (_) {
        granted = false;
      }
    }

    final macosNotifications =
        _notifications.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
    if (macosNotifications != null) {
      try {
        final result = await macosNotifications.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = granted && (result ?? true);
      } catch (_) {
        granted = false;
      }
    }

    return granted;
  }

  Future<bool> _areNotificationsEnabled() async {
    final androidNotifications =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidNotifications != null) {
      try {
        final enabled = await androidNotifications.areNotificationsEnabled();
        return enabled ?? false;
      } catch (_) {
        return false;
      }
    }

    return true;
  }

  bool get permissionGranted => _permissionGranted;

  Future<bool> requestPermission() async {
    if (!_initialized) {
      await initialize(requestPermission: false);
    }
    _permissionGranted = await _requestPermissionsIfNeeded();
    return _permissionGranted;
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> showConnectedNotification({
    String? title,
    String? body,
    String? payload,
    ConnectionTexts texts = const ConnectionTexts(),
  }) async {
    if (!_initialized) await initialize(requestPermission: false);
    if (!_permissionGranted) return;

    final androidDetails = AndroidNotificationDetails(
      'connection_monitor',
      texts.notificationsChannelName,
      channelDescription: texts.notificationsChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      color: Colors.green,
      icon: '@mipmap/ic_launcher',
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      1,
      title ?? texts.notificationConnectedTitle,
      body ?? texts.notificationConnectedBody,
      platformDetails,
      payload: payload,
    );
  }

  Future<void> showDisconnectedNotification({
    String? title,
    String? body,
    String? payload,
    ConnectionTexts texts = const ConnectionTexts(),
  }) async {
    if (!_initialized) await initialize(requestPermission: false);
    if (!_permissionGranted) return;

    final androidDetails = AndroidNotificationDetails(
      'connection_monitor',
      texts.notificationsChannelName,
      channelDescription: texts.notificationsChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.red,
      icon: '@mipmap/ic_launcher',
      ongoing: true,
      autoCancel: false,
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      2,
      title ?? texts.notificationDisconnectedTitle,
      body ?? texts.notificationDisconnectedBody,
      platformDetails,
      payload: payload,
    );
  }

  Future<void> clearConnectedNotification() async {
    await _notifications.cancel(1);
  }

  Future<void> clearDisconnectedNotification() async {
    await _notifications.cancel(2);
  }

  Future<void> clearAllNotifications() async {
    await _notifications.cancelAll();
  }
}

class ConnectionNotificationHandler extends StatefulWidget {
  final Widget child;
  final bool showNotifications;
  final bool showConnectedNotification;
  final String? connectedTitle;
  final String? connectedBody;
  final String? disconnectedTitle;
  final String? disconnectedBody;
  final ConnectionTexts texts;

  const ConnectionNotificationHandler({
    super.key,
    required this.child,
    this.showNotifications = true,
    this.showConnectedNotification = true,
    this.connectedTitle,
    this.connectedBody,
    this.disconnectedTitle,
    this.disconnectedBody,
    this.texts = const ConnectionTexts(),
  });

  @override
  State<ConnectionNotificationHandler> createState() =>
      _ConnectionNotificationHandlerState();
}

class _ConnectionNotificationHandlerState
    extends State<ConnectionNotificationHandler> with WidgetsBindingObserver {
  final ConnectionNotificationService _notificationService =
      ConnectionNotificationService();
  ConnectionMonitorState? lastState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.showNotifications) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _notificationService.initialize(requestPermission: false);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      context.read<ConnectionCubit>().checkInitialConnection();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectionCubit, ConnectionMonitorState>(
      listener: (context, state) {
        if (!widget.showNotifications) return;

        if (lastState != null && lastState!.status == state.status) return;

        switch (state.status) {
          case ConnectionStatus.connected:
            _notificationService.clearDisconnectedNotification();
            if (widget.showConnectedNotification) {
              _notificationService.showConnectedNotification(
                title: widget.connectedTitle,
                body: widget.connectedBody,
                texts: widget.texts,
              );
            }
            break;

          case ConnectionStatus.disconnected:
            _notificationService.clearConnectedNotification();
            _notificationService.showDisconnectedNotification(
              title: widget.disconnectedTitle,
              body: widget.disconnectedBody,
              texts: widget.texts,
            );
            break;

          case ConnectionStatus.checking:
            break;
        }

        lastState = state;
      },
      child: widget.child,
    );
  }
}
