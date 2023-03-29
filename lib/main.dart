import "dart:async";
import "dart:io";

import "package:demo/pdf/pdf_view_widget.dart";
import "package:demo/utils.dart";
import "package:demo/webview/cookie_widget.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_analytics/firebase_analytics.dart";
import "package:firebase_crashlytics/firebase_crashlytics.dart";
import "package:firebase_performance/firebase_performance.dart";
import "package:fcm_config/fcm_config.dart";
import "package:flutter/scheduler.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:timezone/timezone.dart";
import "package:uni_links/uni_links.dart";
import "package:url_launcher/url_launcher.dart";

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  "high_importance_channel", // id
  "High Importance Notifications", // title
  description: "This channel is used for important notifications.",
  importance: Importance.high,
);

Map<String, String> parameters = {};
BuildContext? _context;

Future<void> backGroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("[BACKGROUND] Handling a BACKGROUND message: ${message.messageId}");
    print("[BACKGROUND] Message data: ${message.data}");
    if (message.notification != null) {
      print(
          "[BACKGROUND] Message also contained a notification: ${message.notification}");
    }
  }
  final prefs = await SharedPreferences.getInstance();
  message.data.forEach((key, value) async {
    await prefs.setString(key, value);
  });
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  if (_context != null) {
    Navigator.push(_context!,
        MaterialPageRoute(builder: (context) => const CookieWidget()));
  }
}

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    final notificationsPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await notificationsPlugin?.createNotificationChannel(channel);
    FirebaseMessaging.onBackgroundMessage(backGroundHandler);
    FCMConfig.instance.init(
        onBackgroundMessage: backGroundHandler, defaultAndroidChannel: channel);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        print(
            "[FOREGROUND] Handling a FOREGROUND message: ${message.messageId}");
        print("[FOREGROUND] Message data: ${message.data}");
        if (message.notification != null) {
          print(
              "[FOREGROUND] Message also contained a notification: ${message.notification}");
        }
        final prefs = await SharedPreferences.getInstance();
        message.data.forEach((key, value) async {
          await prefs.setString(key, value);
        });
        if (_context != null) {
          Navigator.push(_context!,
              MaterialPageRoute(builder: (context) => const CookieWidget()));
        }
      }
    });
    await notificationsPlugin?.requestPermission();
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
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
    final url = await getInitialLink();
    if (kDebugMode) {
      print("getInitialLink() - url = ${url ?? ""}");
    }
    parameters = handleLink(url);
    linkStream.listen((String? url) async {
      if (kDebugMode) {
        print("linkStream.listen - url = ${url ?? ""}");
      }
      parameters = handleLink(url);
    }, onDone: () {
      if (kDebugMode) {
        print("linkStream.listen DONE");
      }
    }, onError: (error) {
      if (kDebugMode) {
        print("linkStream.listen ERROR = $error");
      }
    });
    runApp(const MyApp());
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

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
    final adId =
        Platform.isAndroid ? await findAdIdAndroid() : await findAdIdIOS();
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
    _context = context;
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
                const parameters = <String, dynamic>{
                  "string": "Event Name",
                  "int": 1,
                  "long": -1,
                  "double": double.infinity,
                  "bool": true,
                };
                await logFirebaseEvent("test_event", parameters);
              },
            ),
            ElevatedButton(
              child: const Text("Show Messaging Token"),
              onPressed: () async {
                String? token = await FirebaseMessaging.instance.getToken();
                if (kDebugMode) {
                  print("token is ${token ?? ""}");
                }
                if (context.mounted) {
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
                      });
                }
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
                      iOS: const DarwinNotificationDetails(
                        presentAlert: true,
                        presentBadge: true,
                        presentSound: true,
                      ),
                    ),
                    androidAllowWhileIdle: true,
                    uiLocalNotificationDateInterpretation:
                        UILocalNotificationDateInterpretation.absoluteTime,
                  );
                }),
            ElevatedButton(
                child: const Text("WebView-Native Cookie Linkage"),
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CookieWidget()));
                }),
            ElevatedButton(
                child: const Text("PDF Viewer"),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (BuildContext context,
                              Animation<double> animation,
                              Animation<double> secondaryAnimation) =>
                          const PdfViewWidget(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return const FadeUpwardsPageTransitionsBuilder()
                            .buildTransitions(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const PdfViewWidget()),
                                context,
                                animation,
                                secondaryAnimation,
                                child);
                      },
                    ),
                  );
                }),
            ElevatedButton(
                child: const Text("Open DynamicLink"),
                onPressed: () async {
                  const url =
                      "https://test.test.test/link-test.html"; // FIXME write a valided URL.
                  if (kDebugMode) {
                    print("url is $url");
                  }
                  launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                }),
            ElevatedButton(
              child: const Text("DynamicLink Parameters Check"),
              onPressed: () async {
                var dynamicLinkText = "";
                for (var key in parameters.keys) {
                  final value = parameters[key];
                  if (kDebugMode) {
                    print(
                        "[DynamicLink Parameters] key = $key, value = $value");
                  }
                  dynamicLinkText += "$key : $value\n";
                }
                if (kDebugMode) {
                  print("dynamicLinkText is $dynamicLinkText");
                }
                showDialog<void>(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        title: const Text("DynamicLinkパラメータ"),
                        content: Text(dynamicLinkText),
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
                    });
              },
            ),
            ElevatedButton(
              child: const Text("RemoteMessage Data Check"),
              onPressed: () async {
                var remoteMessagesText = "";
                final prefs = await SharedPreferences.getInstance();
                prefs.getKeys().forEach((key) {
                  final value = prefs.getString(key);
                  if (kDebugMode) {
                    print("[RemoteMessage Data] key = $key, value = $value");
                  }
                  remoteMessagesText += "$key : $value\n";
                });
                if (kDebugMode) {
                  print("remoteMessagesText is $remoteMessagesText");
                }
                await prefs.clear();
                if (context.mounted) {
                  showDialog<void>(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          title: const Text("RemoteMessage Data"),
                          content: Text(remoteMessagesText),
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
                      });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
