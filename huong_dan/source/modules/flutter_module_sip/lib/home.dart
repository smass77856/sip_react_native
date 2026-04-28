import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:siprix_voip_sdk/logs_model.dart';
//import 'dart:io' show Platform;

import 'package:siprix_voip_sdk/network_model.dart';

import 'accounts_list.dart';
import 'calls_list.dart';
import 'calls_model_app.dart';
import 'messages.dart';
import 'settings.dart';
import 'subscr_list.dart';

////////////////////////////////////////////////////////////////////////////////////////
//HomePage

class HomePage extends StatefulWidget {
  static const routeName = "/home";
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

////////////////////////////////////////////////////////////////////////////////////////
//LogsPage - represents diagnostic messages

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Consumer<LogsModel>(
        builder: (context, logsModel, child) {
          return SelectableText(
            logsModel.logStr,
            style: Theme.of(context).textTheme.bodySmall,
          );
        },
      ),
    );
  }
}

class _HomePageState extends State<HomePage> {
  final _pageController = PageController();
  int _selectedPageIndex = 0;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            // back to React Native host
            SystemNavigator.pop();
          },
          child: Icon(Icons.chevron_left),
        ),
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
        titleSpacing: 0,
        title: ListTile(
          title: Text(
            'OneCX',
            style: Theme.of(context).textTheme.headlineSmall,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'www.siprix-voip.com',
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => SystemNavigator.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to RN'),
          ),
          if (Platform.isMacOS)
            IconButton(
              icon: const Icon(Icons.notifications_active),
              tooltip: 'Test Notification',
              onPressed: _testLocalNotification,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _onShowSettings,
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          AccountsListPage(),
          CallsListPage(),
          SubscrListPage(),
          MessagesListPage(),
          LogsPage(),
        ],
      ),
      bottomSheet: _networkLostIndicator(),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.widgets),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(icon: _callsTabIcon(), label: 'Calls'),
          const BottomNavigationBarItem(icon: Icon(Icons.hub), label: 'BLF'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.text_snippet),
            label: 'Logs',
          ),
        ],
        currentIndex: _selectedPageIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onTabTapped,
      ),
    );
  }

  Future<void> initDeviceTokenData() async {
    log("=== initDeviceTokenData called ===");
    log("Platform: ${Platform.operatingSystem}");

    try {
      if (Platform.isAndroid) {
        log("Getting Android FCM token...");
        var token = await FirebaseMessaging.instance.getToken();
        log("✅ Android FCM token: $token");
      } else if (Platform.isIOS) {
        log("Getting iOS FCM token...");
        var token = await FirebaseMessaging.instance.getToken();
        log("✅ iOS FCM token: $token");
      } else if (Platform.isMacOS) {
        log("⚠️ macOS: FCM not supported - using local notifications only");
        // macOS không hỗ trợ FCM, chỉ dùng local notifications
      } else {
        log("⚠️ Unknown platform: ${Platform.operatingSystem}");
      }
    } catch (e) {
      log("❌ Error in initDeviceTokenData: $e");
      log("Stack trace: ${StackTrace.current}");
    }

    log("=== initDeviceTokenData completed ===");
  }

  Future<void> initLocalNotifications() async {
    log("Initializing local notifications for ${Platform.operatingSystem}");

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // macOS settings
    const macOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      macOS: macOSSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        log('Notification tapped: ${details.payload}');
        _handleNotificationTap(details.payload);
      },
    );

    if (Platform.isAndroid) {
      // Create notification channel for Android
      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
      log("✅ Android notification channel created");
    } else if (Platform.isMacOS) {
      // Request permissions for macOS
      final granted = await _localNotifications
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      log("✅ macOS notification permissions granted: $granted");
    }
  }

  @override
  void initState() {
    super.initState();

    final callsModel = context.read<AppCallsModel>();

    //Switch tab when incoming call received
    callsModel.onNewIncomingCall = () {
      if (_selectedPageIndex != 1) _onTabTapped(1);
    };

    // Setup incoming call notification for macOS
    if (Platform.isMacOS) {
      callsModel.onShowIncomingCallNotification = (callerName, callerNumber) {
        _showIncomingCallNotification(callerName, callerNumber);
      };
    }

    initDeviceTokenData();
    // Initialize local notifications for Android and macOS
    if (Platform.isAndroid || Platform.isMacOS) {
      initLocalNotifications();
    }
    // Only setup Firebase Messaging on supported platforms
    if (!Platform.isMacOS && !Platform.isWindows) {
      setupFirebaseMessaging();
    }
  }

  void setupFirebaseMessaging() {
    // Request notification permission (Android 13+)
    FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      // Avoid duplicate call notifications: if it's an incoming call, let Siprix native service show it
      final isIncomingCall = message.data['action'] == 'incoming_call';
      if (isIncomingCall) {
        return;
      }

      // Show local notification when message received
      if (message.notification != null) {
        _showLocalNotification(
          message.notification!.title ?? 'New Message',
          message.notification!.body ?? '',
          message.data.toString(),
        );
      } else {
        // If no notification payload, create one from data
        _showLocalNotification(
          'New Message',
          message.data['message'] ?? 'You have a new message',
          message.data.toString(),
        );
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('A new onMessageOpenedApp event was published!');
      log('Message data: ${message.data}');
    });
  }

  Widget _callsTabIcon() {
    final calls = context.watch<AppCallsModel>();
    const icon = Icon(Icons.phone_in_talk);
    return calls.isEmpty
        ? icon
        : Badge(label: Text('${calls.length}'), child: icon);
  }

  void _handleNotificationTap(String? payload) {
    log("🔔 Notification tapped with payload: $payload");

    if (payload == null) return;

    // Bring app to foreground and switch to appropriate tab
    if (payload == 'incoming_call') {
      // Switch to Calls tab (index 1)
      if (_selectedPageIndex != 1) {
        _onTabTapped(1);
      }
      log("✅ Switched to Calls tab");
    } else if (payload == 'test_payload') {
      log("ℹ️ Test notification tapped");
    }
  }

  Widget? _networkLostIndicator() {
    if (context.watch<NetworkModel>().networkLost) {
      return Container(
        color: Colors.red,
        child: const Text(
          "Internet connection lost",
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }
    return null;
  }

  void _onShowSettings() {
    Navigator.of(context).pushNamed(SettingsPage.routeName);
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedPageIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  void _showIncomingCallNotification(String callerName, String callerNumber) {
    log("📞 Showing incoming call notification: $callerName ($callerNumber)");

    String title = '📞 Incoming Call';
    String body =
        callerName != 'Unknown' ? '$callerName ($callerNumber)' : callerNumber;

    _showLocalNotification(title, body, 'incoming_call');
  }

  Future<void> _showLocalNotification(
    String title,
    String body,
    String payload,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const macOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      macOS: macOSDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    log("📬 Local notification shown: $title - $body");
  }

  void _testLocalNotification() {
    _showLocalNotification(
      'Test Notification',
      'This is a test notification on macOS at ${DateTime.now().toString().substring(11, 19)}',
      'test_payload',
    );
  }
}
