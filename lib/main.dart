import "dart:async";
import "dart:io";

import "package:demo/utils.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_analytics/firebase_analytics.dart";
import "package:firebase_crashlytics/firebase_crashlytics.dart";
import "package:firebase_performance/firebase_performance.dart";
import "package:fcm_config/fcm_config.dart";
import "package:flutter/scheduler.dart";
import "package:timezone/timezone.dart";

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  "high_importance_channel", // id
  "High Importance Notifications", // title
  description: "This channel is used for important notifications.",
  importance: Importance.high,
);

Future<void> backGroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("[BACKGROUND] Handling a BACKGROUND message: ${message.messageId}");
    print("[BACKGROUND] Message data: ${message.data}");
    if (message.notification != null) {
      print("[BACKGROUND] Message also contained a notification: ${message.notification}");
    }
  }
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
}

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    FirebaseMessaging.onBackgroundMessage(backGroundHandler);
    FCMConfig.instance.init(onBackgroundMessage: backGroundHandler, defaultAndroidChannel: channel);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("[FOREGROUND] Handling a FOREGROUND message: ${message.messageId}");
        print("[FOREGROUND] Message data: ${message.data}");
        if (message.notification != null) {
          print("[FOREGROUND] Message also contained a notification: ${message.notification}");
        }
      }
    });
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (kDebugMode) {
      print("User granted permission: ${settings.authorizationStatus}");
    }
    FirebasePerformance performance = FirebasePerformance.instance;
    performance.setPerformanceCollectionEnabled(true);
    runApp(const MyApp());
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter Demo",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      navigatorObservers: [observer],
      home: MainPage(analytics: analytics),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({Key? key, required this.analytics}) : super(key: key);
  final FirebaseAnalytics analytics;

  checkTrackingTransparency() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final adId = Platform.isAndroid ? await findAdIdAndroid() : await findAdIdIOS();
    if (adId == zeroId) {
      analytics.setUserProperty(name: "allow_personalized_ads", value: "false");
    } else {
      analytics.setUserProperty(name: "allow_personalized_ads", value: "true");
    }
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) => {
      checkTrackingTransparency(),
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text("デモ コンテンツ"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text("Crashlytics"),
              onPressed: () {
                FirebaseCrashlytics.instance.crash();
              },
            ),
            ElevatedButton(
              child: const Text("Analytics"),
              onPressed: () async {
                await analytics.logEvent(
                  name: "test_event",
                  parameters: <String, dynamic> {
                    "string": "Event Name",
                    "int": 1,
                    "long": -1,
                    "double": double.infinity,
                    "bool": true,
                  }
                );
              },
            ),
            ElevatedButton(
              child: const Text("Show Messaging Token"),
              onPressed: () async {
                String? token = await FirebaseMessaging.instance.getToken();
                if (kDebugMode) {
                  print("token is ${token ?? ""}");
                }
                showDialog<void>(
                  context: context,
                  builder: (_) {
                    return AlertDialog(
                      title: const Text("通知用デバイストークン"),
                      content: Text(token ?? ""),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, "Cancel"),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, "OK"),
                          child: const Text("OK"),
                        ),
                      ],
                    );
                  }
                );
              },
            ),
            ElevatedButton(
              child: const Text("In-App Messaging"),
              onPressed: () async {
                flutterLocalNotificationsPlugin.zonedSchedule(
                  0,
                  "アプリ内通知のテスト",
                  "これはアプリ内通知のテストメッセージです",
                  TZDateTime.now(UTC).add(const Duration(seconds: 1)),
                  NotificationDetails(
                    android: AndroidNotificationDetails(
                      channel.id,
                      channel.name,
                      channelDescription: channel.description,
                    ),
                    iOS: const IOSNotificationDetails(
                      presentAlert: true,
                      presentBadge: true,
                      presentSound: true,
                    ),
                  ),
                  androidAllowWhileIdle: true,
                  uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
                );
              }
            )
          ],
        ),
      ),
    );
  }
}
