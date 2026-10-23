import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'medicine_alarm_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();

  final NotificationAppLaunchDetails? launchDetails =
  await NotificationService.getNotificationAppLaunchDetails();

  final NotificationResponse? notificationResponse =
      launchDetails?.notificationResponse;

  runApp(
    CareGuardianApp(
      notificationResponse: notificationResponse,
    ),
  );
}

class CareGuardianApp extends StatelessWidget {
  final NotificationResponse? notificationResponse;

  const CareGuardianApp({
    super.key,
    this.notificationResponse,
  });

  @override
  Widget build(BuildContext context) {
    Widget startScreen = const SplashScreen();

    if (notificationResponse != null &&
        notificationResponse!.payload != null) {
      try {
        final Map<String, dynamic> data =
        jsonDecode(notificationResponse!.payload!);

        startScreen = MedicineAlarmScreen(
          medicineName:
          data['medicineName'] ?? '',
          dosage:
          data['dosage'] ?? '',
          foodTiming:
          data['foodTiming'] ?? 'Any Time',
          imagePath:
          data['imagePath'] ?? '',
          alertType:
          data['alertType'] ??
              'Sound + Vibration',
        );
      } catch (e) {
        print(
          'LAUNCH PAYLOAD ERROR: $e',
        );

        startScreen =
        const SplashScreen();
      }
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Care Guardian',
      navigatorKey:
      NotificationService.navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: startScreen,
    );
  }
}