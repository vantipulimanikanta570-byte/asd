
import 'dart:convert';
import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../medicine_alarm_screen.dart';

final FlutterLocalNotificationsPlugin
flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const String historyPrefix = 'medicine_history_';

// ============================================================
// SAVE MEDICINE HISTORY
// ============================================================

Future<void> saveMedicineHistory({
  required String medicineName,
  required String dosage,
}) async {
  // First cancel any remaining 5-minute retry alarms.
  await cancelPendingRetryAlarms(
    medicineName: medicineName,
  );

  final SharedPreferencesAsync prefs =
  SharedPreferencesAsync();

  final String uniqueKey =
      '$historyPrefix${DateTime.now().microsecondsSinceEpoch}';

  final Map<String, dynamic> historyItem = {
    'medicineName': medicineName,
    'dosage': dosage,
    'time': DateTime.now().toIso8601String(),
    'status': 'Taken',
  };

  await prefs.setString(
    uniqueKey,
    jsonEncode(historyItem),
  );

  print(
    'MEDICINE HISTORY SAVED: $medicineName',
  );
}
// ============================================================
// SAVE MISSED MEDICINE HISTORY
// ============================================================

Future<void> saveMissedMedicineHistory({
  required String medicineName,
  required String dosage,
}) async {
  // Cancel any remaining retry alarms.
  await cancelPendingRetryAlarms(
    medicineName: medicineName,
  );

  final SharedPreferencesAsync prefs =
  SharedPreferencesAsync();

  final String uniqueKey =
      '$historyPrefix${DateTime.now().microsecondsSinceEpoch}';

  final Map<String, dynamic> historyItem = {
    'medicineName': medicineName,
    'dosage': dosage,
    'time': DateTime.now().toIso8601String(),
    'status': 'Missed',
  };

  await prefs.setString(
    uniqueKey,
    jsonEncode(historyItem),
  );

  print(
    'MEDICINE HISTORY SAVED AS MISSED: $medicineName',
  );
}

// ============================================================
// NORMALIZE TIME
// ============================================================

String _normalizeTime(String time) {
  final String value =
  time.trim().toUpperCase();

  final RegExp regex = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
  );

  final Match? match =
  regex.firstMatch(value);

  if (match == null) {
    return value;
  }

  final int hour =
  int.parse(match.group(1)!);

  final int minute =
  int.parse(match.group(2)!);

  final String period =
  match.group(3)!;

  return '$hour:${minute.toString().padLeft(2, '0')} $period';
}

// ============================================================
// DATETIME TO TIME STRING
// ============================================================

String _dateTimeToTimeString(
    DateTime time,
    ) {
  int hour = time.hour;

  final int minute = time.minute;

  final String period =
  hour >= 12 ? 'PM' : 'AM';

  if (hour == 0) {
    hour = 12;
  } else if (hour > 12) {
    hour -= 12;
  }

  return '$hour:${minute.toString().padLeft(2, '0')} $period';
}

// ============================================================
// CREATE STABLE NOTIFICATION ID
// ============================================================

int _createNotificationId({
  required String medicineName,
  required String time,
  required String frequency,
  required int type,
}) {
  final String value =
      '${medicineName.trim().toLowerCase()}'
      '|${_normalizeTime(time)}'
      '|${frequency.trim().toLowerCase()}'
      '|$type';

  int hash = 0;

  for (int i = 0; i < value.length; i++) {
    hash =
    (hash * 31 + value.codeUnitAt(i)) &
    0x7fffffff;
  }

  return hash % 1000000;
}

// ============================================================
// MEDICINE NOTIFICATION ID
// ============================================================

int _medicineNotificationId({
  required String medicineName,
  required String time,
  required String frequency,
}) {
  return _createNotificationId(
    medicineName: medicineName,
    time: time,
    frequency: frequency,
    type: 1,
  );
}

// ============================================================
// 30-MINUTE NOTIFICATION ID
// ============================================================

int _advanceNotificationId({
  required String medicineName,
  required String time,
  required String frequency,
}) {
  return _createNotificationId(
    medicineName: medicineName,
    time: time,
    frequency: frequency,
    type: 2,
  );
}

// ============================================================
// RETRY #1 ID
// ============================================================

int _retryOneNotificationId({
  required String medicineName,
  required String time,
  required String frequency,
}) {
  return _createNotificationId(
    medicineName: medicineName,
    time: time,
    frequency: frequency,
    type: 3,
  );
}

// ============================================================
// RETRY #2 ID
// ============================================================

int _retryTwoNotificationId({
  required String medicineName,
  required String time,
  required String frequency,
}) {
  return _createNotificationId(
    medicineName: medicineName,
    time: time,
    frequency: frequency,
    type: 4,
  );
}

// ============================================================
// CANCEL MEDICINE REMINDERS
// ============================================================

Future<void> cancelMedicineReminders({
  required String medicineName,
  required String time,
  required String frequency,
}) async {
  final int medicineId =
  _medicineNotificationId(
    medicineName: medicineName,
    time: time,
    frequency: frequency,
  );

  final int advanceId =
  _advanceNotificationId(
    medicineName: medicineName,
    time: time,
    frequency: frequency,
  );

  final int retryOneId =
  _retryOneNotificationId(
    medicineName: medicineName,
    time: time,
    frequency: frequency,
  );

  final int retryTwoId =
  _retryTwoNotificationId(
    medicineName: medicineName,
    time: time,
    frequency: frequency,
  );

  await flutterLocalNotificationsPlugin
      .cancel(medicineId);

  await flutterLocalNotificationsPlugin
      .cancel(advanceId);

  await flutterLocalNotificationsPlugin
      .cancel(retryOneId);

  await flutterLocalNotificationsPlugin
      .cancel(retryTwoId);

  print(
    'REMINDERS CANCELLED: $medicineName',
  );
}

// ============================================================
// CANCEL ONLY RETRY ALARMS
// ============================================================

Future<void> cancelPendingRetryAlarms({
  required String medicineName,
}) async {
  try {
    final List<PendingNotificationRequest>
    pending =
    await flutterLocalNotificationsPlugin
        .pendingNotificationRequests();

    for (final PendingNotificationRequest item
    in pending) {
      if (item.payload == null) {
        continue;
      }

      try {
        final Map<String, dynamic> data =
        jsonDecode(item.payload!);

        final String pendingMedicine =
            data['medicineName'] ?? '';

        final int retryAttempt =
            data['retryAttempt'] ?? 0;

        if (pendingMedicine ==
            medicineName &&
            retryAttempt > 0) {
          await flutterLocalNotificationsPlugin
              .cancel(item.id);

          print(
            'RETRY ALARM CANCELLED: '
                '$medicineName / Attempt $retryAttempt',
          );
        }
      } catch (_) {
        // Ignore invalid payloads.
      }
    }
  } catch (e) {
    print(
      'ERROR CANCELLING RETRY ALARMS: $e',
    );
  }
}

// ============================================================
// MEDICINE NOTIFICATION DETAILS
// ============================================================

NotificationDetails _medicineNotificationDetails({
  String alertType = 'Sound + Vibration',
  bool fullScreenIntent = false,
}) {
  final bool soundEnabled =
      alertType == 'Sound + Vibration';

  return NotificationDetails(
    android: AndroidNotificationDetails(
      soundEnabled
          ? 'medicine_alarm_sound_channel_v2'
          : 'medicine_vibration_channel',

      soundEnabled
          ? 'Medicine Alarm - Sound + Vibration'
          : 'Medicine Alarm - Vibration Only',

      channelDescription:
      soundEnabled
          ? 'Medicine alarm with sound and vibration'
          : 'Medicine alarm with vibration only',

      importance: Importance.max,
      priority: Priority.high,

      fullScreenIntent:
      fullScreenIntent,

      playSound:
      soundEnabled,

      sound: soundEnabled
          ? const RawResourceAndroidNotificationSound(
        'medicine_alarm',
      )
          : null,

      timeoutAfter:
      soundEnabled ? 60000 : null,

      audioAttributesUsage:
      AudioAttributesUsage.alarm,

      enableVibration: true,

      vibrationPattern:
      Int64List.fromList([
        0,
        1000,
        500,
        1000,
        500,
        1000,
        500,
        1000,
        500,
        1000,
        500,
        1000,
        500,
        1000,
      ]),

      actions: [
        AndroidNotificationAction(
          'TAKEN',
          'TAKEN',
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'SNOOZE',
          'SNOOZE 10 MIN',
          cancelNotification: true,
        ),
      ],
    ),
  );
}

// ============================================================
// CREATE PAYLOAD
// ============================================================

String _createPayload({
  required String medicineName,
  required String dosage,
  String alertType = 'Sound + Vibration',
  String foodTiming = 'Any Time',
  String imagePath = '',
  int retryAttempt = 0,
}) {
  return jsonEncode({
    'medicineName': medicineName,
    'dosage': dosage,
    'alertType': alertType,
    'foodTiming': foodTiming,
    'imagePath': imagePath,

    // 0 = original alarm
    // 1 = first retry
    // 2 = second retry
    'retryAttempt': retryAttempt,
  });
}

// ============================================================
// SNOOZE
// ============================================================

Future<void> scheduleSnoozeNotification({
  required String medicineName,
  required String dosage,
  String alertType =
  'Sound + Vibration',
}) async {
  print(
    'SNOOZE FUNCTION STARTED',
  );

  // Cancel the automatic 5-minute retry alarms.
  await cancelPendingRetryAlarms(
    medicineName: medicineName,
  );

  DartPluginRegistrant.ensureInitialized();

  tzdata.initializeTimeZones();

  tz.setLocalLocation(
    tz.getLocation('Asia/Kolkata'),
  );

  final FlutterLocalNotificationsPlugin
  snoozePlugin =
  FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings
  androidSettings =
  AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  const InitializationSettings
  settings =
  InitializationSettings(
    android: androidSettings,
  );

  await snoozePlugin.initialize(
    settings,
    onDidReceiveBackgroundNotificationResponse:
    notificationTapBackground,
  );

  final tz.TZDateTime now =
  tz.TZDateTime.now(
    tz.local,
  );

  final tz.TZDateTime snoozeTime =
  now.add(
    const Duration(minutes: 10),
  );

  final AndroidFlutterLocalNotificationsPlugin?
  androidPlugin =
  snoozePlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  final bool? canUseExact =
  await androidPlugin
      ?.canScheduleExactNotifications();

  print(
    'EXACT ALARM PERMISSION: $canUseExact',
  );

  if (canUseExact != true) {
    print(
      'ERROR: EXACT ALARM PERMISSION IS NOT AVAILABLE.',
    );

    return;
  }

  final int notificationId =
  DateTime.now()
      .millisecondsSinceEpoch
      .remainder(1000000);

  final String payload =
  _createPayload(
    medicineName: medicineName,
    dosage: dosage,
    alertType: alertType,
    retryAttempt: 0,
  );

  await snoozePlugin.zonedSchedule(
    notificationId,
    'Snoozed Medicine 💊',
    'Time to take $medicineName. Dosage: $dosage',
    snoozeTime,
    _medicineNotificationDetails(
      alertType: alertType,
      fullScreenIntent: true,
    ),
    androidScheduleMode:
    AndroidScheduleMode.alarmClock,
    payload: payload,
  );

  print(
    'SNOOZE SUCCESSFULLY SCHEDULED',
  );

  print(
    'SNOOZE WILL FIRE AT: $snoozeTime',
  );
}

// ============================================================
// BACKGROUND NOTIFICATION ACTION
// ============================================================

@pragma('vm:entry-point')
void notificationTapBackground(
    NotificationResponse response,
    ) async {
  print(
    'BACKGROUND NOTIFICATION ACTION RECEIVED',
  );

  DartPluginRegistrant.ensureInitialized();

  if (response.payload == null) {
    print(
      'BACKGROUND ACTION HAS NO PAYLOAD',
    );

    return;
  }

  try {
    final Map<String, dynamic> data =
    jsonDecode(
      response.payload!,
    );

    final String medicineName =
        data['medicineName'] ?? '';

    final String dosage =
        data['dosage'] ?? '';

    final String alertType =
        data['alertType'] ??
            'Sound + Vibration';

    if (response.actionId == 'TAKEN') {
      await saveMedicineHistory(
        medicineName: medicineName,
        dosage: dosage,
      );

      print(
        'MEDICINE TAKEN: $medicineName',
      );

      return;
    }

    if (response.actionId == 'SNOOZE') {
      print(
        'SNOOZE PRESSED: $medicineName',
      );

      await scheduleSnoozeNotification(
        medicineName: medicineName,
        dosage: dosage,
        alertType: alertType,
      );

      return;
    }

    print(
      'UNKNOWN ACTION: ${response.actionId}',
    );
  } catch (e, stackTrace) {
    print(
      'BACKGROUND ACTION ERROR: $e',
    );

    print(
      stackTrace,
    );
  }
}

// ============================================================
// NOTIFICATION SERVICE
// ============================================================

class NotificationService {
  // ==========================================================
  // NAVIGATOR KEY
  // ==========================================================

  static final GlobalKey<NavigatorState>
  navigatorKey =
  GlobalKey<NavigatorState>();

  // ==========================================================
  // APP LAUNCH DETAILS
  // ==========================================================

  static Future<
      NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async {
    return await flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();
  }

  // ==========================================================
  // INITIALIZE
  // ==========================================================

  static Future<void> initialize() async {
    tzdata.initializeTimeZones();

    tz.setLocalLocation(
      tz.getLocation('Asia/Kolkata'),
    );

    const AndroidInitializationSettings
    androidSettings =
    AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings
    settings =
    InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin
        .initialize(
      settings,
      onDidReceiveNotificationResponse:
      _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
      notificationTapBackground,
    );

    final AndroidFlutterLocalNotificationsPlugin?
    androidPlugin =
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin
        ?.requestNotificationsPermission();

    await androidPlugin
        ?.requestFullScreenIntentPermission();

    await androidPlugin
        ?.requestExactAlarmsPermission();

    final bool? exactPermission =
    await androidPlugin
        ?.canScheduleExactNotifications();

    print(
      'EXACT ALARM PERMISSION: $exactPermission',
    );
  }

  // ==========================================================
  // CLOSE ALL MEDICINE ALARM SCREENS
  // ==========================================================

  static void closeAllMedicineAlarmScreens() {
    final NavigatorState? navigator =
        NotificationService.navigatorKey.currentState;

    if (navigator == null) {
      return;
    }

    print(
      'CLOSING ALL MEDICINE ALARM SCREENS',
    );

    navigator.popUntil(
          (route) =>
      route.settings.name != '/medicineAlarm',
    );
  }

  // ==========================================================
  // NOTIFICATION RESPONSE
  // ==========================================================

  static Future<void>
  _onNotificationResponse(
      NotificationResponse response,
      ) async {
    print(
      'NOTIFICATION RESPONSE: ${response.actionId}',
    );

    if (response.payload == null) {
      print(
        'NOTIFICATION RESPONSE HAS NO PAYLOAD',
      );

      return;
    }

    try {
      final Map<String, dynamic> data =
      jsonDecode(
        response.payload!,
      );

      final String medicineName =
          data['medicineName'] ?? '';

      final String dosage =
          data['dosage'] ?? '';

      final String alertType =
          data['alertType'] ??
              'Sound + Vibration';

      final String foodTiming =
          data['foodTiming'] ??
              'Any Time';

      final String imagePath =
          data['imagePath'] ?? '';

      final int retryAttempt =
          data['retryAttempt'] ?? 0;

      // ======================================================
      // TAKEN
      // ======================================================

      if (response.actionId == 'TAKEN') {
        await saveMedicineHistory(
          medicineName: medicineName,
          dosage: dosage,
        );

        print(
          'MEDICINE TAKEN: $medicineName',
        );

        closeAllMedicineAlarmScreens();

        return;
      }

      // ======================================================
      // SNOOZE
      // ======================================================

      if (response.actionId == 'SNOOZE') {
        print(
          'SNOOZE PRESSED: $medicineName',
        );

        await scheduleSnoozeNotification(
          medicineName: medicineName,
          dosage: dosage,
          alertType: alertType,
        );

        closeAllMedicineAlarmScreens();

        return;
      }

      // ======================================================
      // FULL SCREEN MEDICINE ALARM
      // ======================================================

      if (response.actionId == null ||
          response.actionId!.isEmpty) {
        print(
          'FULL SCREEN ALARM RESPONSE RECEIVED',
        );

        // Keep only ONE alarm screen.
        // Attempt 1 opens it.
        // Attempt 2 reuses it.
        // Attempt 3 reuses it and starts MISSED timer.

        if (MedicineAlarmScreenState.isAlarmScreenOpen) {
          print(
            'ALARM SCREEN ALREADY OPEN - '
                'NOT OPENING ANOTHER SCREEN',
          );

          if (retryAttempt == 2) {
            MedicineAlarmScreenState.startFinalMissedTimer();
          }

          return;
        }

        for (int i = 0; i < 20; i++) {
          final NavigatorState? navigator =
              NotificationService
                  .navigatorKey
                  .currentState;

          if (navigator != null) {
            print(
              'NAVIGATOR READY',
            );

            navigator.push(
              MaterialPageRoute(
                settings:
                const RouteSettings(
                  name: '/medicineAlarm',
                ),
                builder: (context) =>
                    MedicineAlarmScreen(
                      medicineName: medicineName,
                      dosage: dosage,
                      foodTiming: foodTiming,
                      imagePath: imagePath,
                      alertType: alertType,
                      retryAttempt: retryAttempt,
                    ),
              ),
            );

            print(
              'MEDICINE ALARM SCREEN OPENED: '
                  '$medicineName / Attempt $retryAttempt',
            );

            return;
          }

          print(
            'NAVIGATOR NOT READY - WAITING...',
          );

          await Future.delayed(
            const Duration(
              milliseconds: 250,
            ),
          );
        }

        print(
          'ERROR: NAVIGATOR DID NOT BECOME READY',
        );
      }
    } catch (e, stackTrace) {
      print(
        'NOTIFICATION RESPONSE ERROR: $e',
      );

      print(
        stackTrace,
      );
    }
  }

  // ==========================================================
  // SCHEDULE MEDICINE REMINDER
  // ==========================================================

  static Future<void>
  scheduleMedicineReminder({
    required String medicineName,
    required String dosage,
    required DateTime time,
    required String frequency,
    String alertType =
    'Sound + Vibration',
    String foodTiming =
    'Any Time',
    String imagePath = '',
  }) async {
    tzdata.initializeTimeZones();

    tz.setLocalLocation(
      tz.getLocation('Asia/Kolkata'),
    );

    final tz.TZDateTime now =
    tz.TZDateTime.now(
      tz.local,
    );

    tz.TZDateTime scheduledTime =
    tz.TZDateTime(
      tz.local,
      time.year,
      time.month,
      time.day,
      time.hour,
      time.minute,
    );

    // If time already passed,
    // schedule for tomorrow.
    if (scheduledTime.isBefore(now)) {
      scheduledTime =
          scheduledTime.add(
            const Duration(days: 1),
          );
    }

    // ========================================================
    // CANCEL OLD RETRIES
    // ========================================================

    final String timeString =
    _dateTimeToTimeString(time);

    final int oldRetryOneId =
    _retryOneNotificationId(
      medicineName: medicineName,
      time: timeString,
      frequency: frequency,
    );

    final int oldRetryTwoId =
    _retryTwoNotificationId(
      medicineName: medicineName,
      time: timeString,
      frequency: frequency,
    );

    await flutterLocalNotificationsPlugin
        .cancel(oldRetryOneId);

    await flutterLocalNotificationsPlugin
        .cancel(oldRetryTwoId);

    // ========================================================
    // 30-MINUTE ALERT
    // ========================================================

    tz.TZDateTime? advanceAlertTime;

    final tz.TZDateTime
    calculatedAdvanceTime =
    scheduledTime.subtract(
      const Duration(minutes: 30),
    );

    if (calculatedAdvanceTime.isAfter(now)) {
      advanceAlertTime =
          calculatedAdvanceTime;
    }

    final int medicineNotificationId =
    _medicineNotificationId(
      medicineName: medicineName,
      time: timeString,
      frequency: frequency,
    );

    final int advanceNotificationId =
    _advanceNotificationId(
      medicineName: medicineName,
      time: timeString,
      frequency: frequency,
    );

    final int retryOneId =
    _retryOneNotificationId(
      medicineName: medicineName,
      time: timeString,
      frequency: frequency,
    );

    final int retryTwoId =
    _retryTwoNotificationId(
      medicineName: medicineName,
      time: timeString,
      frequency: frequency,
    );

    final String payload =
    _createPayload(
      medicineName: medicineName,
      dosage: dosage,
      alertType: alertType,
      foodTiming: foodTiming,
      imagePath: imagePath,
      retryAttempt: 0,
    );

    // ========================================================
    // 30-MINUTE NOTIFICATION DETAILS
    // ========================================================

    const NotificationDetails
    advanceNotificationDetails =
    NotificationDetails(
      android:
      AndroidNotificationDetails(
        'medicine_advance_channel',
        'Medicine Advance Reminder',
        channelDescription:
        'Reminder before medicine time',
        importance:
        Importance.high,
        priority:
        Priority.high,
      ),
    );

    // ========================================================
    // CHECK EXACT ALARM PERMISSION
    // ========================================================

    final AndroidFlutterLocalNotificationsPlugin?
    androidPlugin =
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final bool? canUseExact =
    await androidPlugin
        ?.canScheduleExactNotifications();

    print(
      'EXACT ALARM PERMISSION: $canUseExact',
    );

    if (canUseExact != true) {
      print(
        'ERROR: EXACT ALARM PERMISSION IS NOT AVAILABLE.',
      );

      return;
    }

    // ========================================================
    // SCHEDULE 30-MINUTE ALERT
    // ========================================================

    if (advanceAlertTime != null) {
      if (frequency == 'Every Day') {
        await flutterLocalNotificationsPlugin
            .zonedSchedule(
          advanceNotificationId,
          'Medicine Reminder 🔔',
          '$medicineName is due in 30 minutes. '
              'Dosage: $dosage',
          advanceAlertTime,
          advanceNotificationDetails,
          androidScheduleMode:
          AndroidScheduleMode
              .exactAllowWhileIdle,
          matchDateTimeComponents:
          DateTimeComponents.time,
          payload: payload,
        );
      } else {
        await flutterLocalNotificationsPlugin
            .zonedSchedule(
          advanceNotificationId,
          'Medicine Reminder 🔔',
          '$medicineName is due in 30 minutes. '
              'Dosage: $dosage',
          advanceAlertTime,
          advanceNotificationDetails,
          androidScheduleMode:
          AndroidScheduleMode
              .exactAllowWhileIdle,
          payload: payload,
        );
      }
    }

    // ========================================================
    // ACTUAL MEDICINE ALERT DETAILS
    // ========================================================

    final NotificationDetails
    medicineDetails =
    _medicineNotificationDetails(
      alertType: alertType,
      fullScreenIntent: true,
    );

    // ========================================================
    // ATTEMPT 1
    // ========================================================

    if (frequency == 'Every Day') {
      await flutterLocalNotificationsPlugin
          .zonedSchedule(
        medicineNotificationId,
        'Time to take $medicineName 💊',
        'Dosage: $dosage',
        scheduledTime,
        medicineDetails,

        // KEEP EXACT TIME
        androidScheduleMode:
        AndroidScheduleMode.alarmClock,

        matchDateTimeComponents:
        DateTimeComponents.time,

        payload: payload,
      );
    } else {
      await flutterLocalNotificationsPlugin
          .zonedSchedule(
        medicineNotificationId,
        'Time to take $medicineName 💊',
        'Dosage: $dosage',
        scheduledTime,
        medicineDetails,

        // KEEP EXACT TIME
        androidScheduleMode:
        AndroidScheduleMode.alarmClock,

        payload: payload,
      );
    }

    // ========================================================
    // ATTEMPT 2 — AFTER 5 MINUTES
    // ========================================================

    final tz.TZDateTime retryOneTime =
    scheduledTime.add(
      const Duration(minutes: 5),
    );

    final String retryOnePayload =
    _createPayload(
      medicineName: medicineName,
      dosage: dosage,
      alertType: alertType,
      foodTiming: foodTiming,
      imagePath: imagePath,
      retryAttempt: 1,
    );

    if (frequency == 'Every Day') {
      await flutterLocalNotificationsPlugin
          .zonedSchedule(
        retryOneId,
        'Medicine Reminder 🔔',
        '$medicineName was not responded to. '
            'Time to take your medicine.',
        retryOneTime,
        medicineDetails,
        androidScheduleMode:
        AndroidScheduleMode.alarmClock,
        matchDateTimeComponents:
        DateTimeComponents.time,
        payload: retryOnePayload,
      );
    } else {
      await flutterLocalNotificationsPlugin
          .zonedSchedule(
        retryOneId,
        'Medicine Reminder 🔔',
        '$medicineName was not responded to. '
            'Time to take your medicine.',
        retryOneTime,
        medicineDetails,
        androidScheduleMode:
        AndroidScheduleMode.alarmClock,
        payload: retryOnePayload,
      );
    }

    // ========================================================
    // ATTEMPT 3 — AFTER 10 MINUTES
    // ========================================================

    final tz.TZDateTime retryTwoTime =
    scheduledTime.add(
      const Duration(minutes: 10),
    );

    final String retryTwoPayload =
    _createPayload(
      medicineName: medicineName,
      dosage: dosage,
      alertType: alertType,
      foodTiming: foodTiming,
      imagePath: imagePath,
      retryAttempt: 2,
    );

    if (frequency == 'Every Day') {
      await flutterLocalNotificationsPlugin
          .zonedSchedule(
        retryTwoId,
        'Medicine Reminder 🔔',
        '$medicineName was not responded to. '
            'Final medicine reminder.',
        retryTwoTime,
        medicineDetails,
        androidScheduleMode:
        AndroidScheduleMode.alarmClock,
        matchDateTimeComponents:
        DateTimeComponents.time,
        payload: retryTwoPayload,
      );
    } else {
      await flutterLocalNotificationsPlugin
          .zonedSchedule(
        retryTwoId,
        'Medicine Reminder 🔔',
        '$medicineName was not responded to. '
            'Final medicine reminder.',
        retryTwoTime,
        medicineDetails,
        androidScheduleMode:
        AndroidScheduleMode.alarmClock,
        payload: retryTwoPayload,
      );
    }

    // ========================================================
    // DEBUG INFORMATION
    // ========================================================

    print(
      '================================================',
    );

    print(
      'MEDICINE: $medicineName',
    );

    print(
      'CURRENT TIME: $now',
    );

    print(
      'ATTEMPT 1: $scheduledTime',
    );

    print(
      'ATTEMPT 2: $retryOneTime',
    );

    print(
      'ATTEMPT 3: $retryTwoTime',
    );

    print(
      '30 MIN ALERT: $advanceAlertTime',
    );

    print(
      'MEDICINE ID: $medicineNotificationId',
    );

    print(
      'RETRY 1 ID: $retryOneId',
    );

    print(
      'RETRY 2 ID: $retryTwoId',
    );

    print(
      'FREQUENCY: $frequency',
    );

    print(
      'ALERT TYPE: $alertType',
    );

    print(
      'FULL SCREEN INTENT: ENABLED',
    );

    print(
      'ALARM CLOCK MODE: ENABLED',
    );

    print(
      '3-ATTEMPT SYSTEM: ENABLED',
    );

    print(
      '================================================',
    );
  }

  // ==========================================================
  // TEST NOTIFICATION
  // ==========================================================

  static Future<void>
  testNotification() async {
    await flutterLocalNotificationsPlugin
        .show(
      999,
      'Test Notification',
      'Care Guardian notification is working!',
      const NotificationDetails(
        android:
        AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription:
          'Test notification channel',
          importance:
          Importance.high,
          priority:
          Priority.high,
        ),
      ),
    );
  }
}

