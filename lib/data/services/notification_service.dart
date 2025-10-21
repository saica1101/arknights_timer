import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();

  // Windows 用の識別子（固定値）
  static const String _windowsAppUserModelId = 'com.example.arknights_timer';
  static const String _windowsAppName = 'アークナイツタイマー';
  // GUID 形式（固定）: 生成済みのサンプル GUID。必要なら任意の GUID に置き換え可能。
  static const String _windowsGuid = '8a6c7e3e-5f1b-4c3a-9a4e-6c3f9c2a9b71';

  // Android 通知チャンネル定義（文字列定数で管理）
  static const String _androidChannelId = 'arknights_channel';
  static const String _androidChannelName = 'Arknights Timer';
  static const String _androidChannelDescription = '理性が全回復したときに通知します';
  static const int _scheduledId = 1001;

  Future<void> initialize() async {
    // Android と Windows の両方の設定を用意（Windows 実行時は必須）
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const windowsInit = WindowsInitializationSettings(
      appName: _windowsAppName,
      appUserModelId: _windowsAppUserModelId,
      guid: _windowsGuid,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      windows: windowsInit,
    );

    await _plugin.initialize(initSettings);

    // Android: 通知権限（Android 13+）のリクエストとチャンネル作成
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // 権限リクエスト（必要な場合のみ表示される）
      await Permission.notification.request();

      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          description: _androidChannelDescription,
          importance: Importance.max,
        ),
      );

      // Android 12+ で厳密アラームを使う場合の許可（設定画面を開く）
      await androidImpl?.requestExactAlarmsPermission();
    }

    // タイムゾーン初期化（スケジュール通知用）
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      // フォールバック: 失敗時は UTC
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> sendRecoveryNotification() async {
    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );
    const windowsDetails = WindowsNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      windows: windowsDetails,
    );

    await _plugin.show(0, 'アークナイツタイマー', '理性が全回復しました！ゲームをプレイしましょう。', details);
  }

  /// 指定時刻に「理性が全回復」の通知を予約する（ローカルタイムゾーン基準）。
  Future<void> scheduleRecoveryNotification(DateTime when) async {
    try {
      final scheduled = tz.TZDateTime.from(when, tz.local);
      const androidDetails = AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
      );
      const windowsDetails = WindowsNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        windows: windowsDetails,
      );

      await _plugin.zonedSchedule(
        _scheduledId,
        'アークナイツタイマー',
        '理性が全回復しました！ゲームをプレイしましょう。',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // プラットフォーム未対応や権限不足などで失敗した場合は握りつぶす
    }
  }

  Future<void> cancelScheduledRecoveryNotification() async {
    try {
      await _plugin.cancel(_scheduledId);
    } catch (_) {}
  }
}
