import 'package:flutter/foundation.dart';

@immutable
class ConnectionTexts {
  final String connectedMessage;
  final String disconnectedMessage;
  final String checkingMessage;
  final String checkFailedPrefix;
  final String retryActionLabel;
  final String unknownConnectionType;
  final String typeWifi;
  final String typeEthernet;
  final String typeMobile;
  final String typeBluetooth;
  final String typeVpn;
  final String typeOther;
  final String typeNone;
  final String notificationConnectedTitle;
  final String notificationConnectedBody;
  final String notificationDisconnectedTitle;
  final String notificationDisconnectedBody;
  final String notificationsChannelName;
  final String notificationsChannelDescription;

  const ConnectionTexts({
    this.connectedMessage = 'Internet connection is active',
    this.disconnectedMessage = 'No internet connection',
    this.checkingMessage = 'Checking connection...',
    this.checkFailedPrefix = 'Connection check failed',
    this.retryActionLabel = 'Retry',
    this.unknownConnectionType = 'Unknown',
    this.typeWifi = 'WiFi',
    this.typeEthernet = 'Ethernet',
    this.typeMobile = 'Mobile',
    this.typeBluetooth = 'Bluetooth',
    this.typeVpn = 'VPN',
    this.typeOther = 'Other',
    this.typeNone = 'None',
    this.notificationConnectedTitle = 'Internet Connected',
    this.notificationConnectedBody = 'Your device is connected to the internet',
    this.notificationDisconnectedTitle = 'Internet Disconnected',
    this.notificationDisconnectedBody =
        'Your device is not connected to the internet',
    this.notificationsChannelName = 'Connection Notifications',
    this.notificationsChannelDescription =
        'Internet connection status notifications',
  });

  ConnectionTexts copyWith({
    String? connectedMessage,
    String? disconnectedMessage,
    String? checkingMessage,
    String? checkFailedPrefix,
    String? retryActionLabel,
    String? unknownConnectionType,
    String? typeWifi,
    String? typeEthernet,
    String? typeMobile,
    String? typeBluetooth,
    String? typeVpn,
    String? typeOther,
    String? typeNone,
    String? notificationConnectedTitle,
    String? notificationConnectedBody,
    String? notificationDisconnectedTitle,
    String? notificationDisconnectedBody,
    String? notificationsChannelName,
    String? notificationsChannelDescription,
  }) {
    return ConnectionTexts(
      connectedMessage: connectedMessage ?? this.connectedMessage,
      disconnectedMessage: disconnectedMessage ?? this.disconnectedMessage,
      checkingMessage: checkingMessage ?? this.checkingMessage,
      checkFailedPrefix: checkFailedPrefix ?? this.checkFailedPrefix,
      retryActionLabel: retryActionLabel ?? this.retryActionLabel,
      unknownConnectionType:
          unknownConnectionType ?? this.unknownConnectionType,
      typeWifi: typeWifi ?? this.typeWifi,
      typeEthernet: typeEthernet ?? this.typeEthernet,
      typeMobile: typeMobile ?? this.typeMobile,
      typeBluetooth: typeBluetooth ?? this.typeBluetooth,
      typeVpn: typeVpn ?? this.typeVpn,
      typeOther: typeOther ?? this.typeOther,
      typeNone: typeNone ?? this.typeNone,
      notificationConnectedTitle:
          notificationConnectedTitle ?? this.notificationConnectedTitle,
      notificationConnectedBody:
          notificationConnectedBody ?? this.notificationConnectedBody,
      notificationDisconnectedTitle:
          notificationDisconnectedTitle ?? this.notificationDisconnectedTitle,
      notificationDisconnectedBody:
          notificationDisconnectedBody ?? this.notificationDisconnectedBody,
      notificationsChannelName:
          notificationsChannelName ?? this.notificationsChannelName,
      notificationsChannelDescription: notificationsChannelDescription ??
          this.notificationsChannelDescription,
    );
  }
}
