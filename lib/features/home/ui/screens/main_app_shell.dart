import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:lychakingo/features/translator/ui/screens/translation_screen.dart';
import 'package:lychakingo/features/ai_tutor/ui/screens/ai_qa_screen.dart';
import 'package:lychakingo/features/lessons/ui/screens/lesson_list_screen.dart';
import 'package:lychakingo/features/home/ui/screens/home_screen.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('Notification(${notificationResponse.id}) tapped in background: payload=${notificationResponse.payload}');
}

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeAndScheduleNotificationsForAndroid();
      });
    }
  }

  Future<void> _initializeAndScheduleNotificationsForAndroid() async {
    await _configureLocalTimeZone();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    bool? initialized = await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        final String? payload = notificationResponse.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint('NOTIFICATION PAYLOAD (onDidReceiveNotificationResponse): $payload');
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Notification tapped with payload: $payload"))
            );
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    print("Local notifications plugin initialized for Android: $initialized");

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    final bool? notificationPermissionGranted = await androidImplementation?.requestNotificationsPermission();
    print("Android Notification permission granted: $notificationPermissionGranted");

    final bool? exactAlarmPermissionGranted = await androidImplementation?.requestExactAlarmsPermission();
    print("Android Exact alarm permission granted: $exactAlarmPermissionGranted");

    if (notificationPermissionGranted == true || exactAlarmPermissionGranted == true) {
        await _scheduleDailyLessonReminder();
    } else {
        print("Android notification/exact alarm permissions not granted, reminder not scheduled.");
    }
  }

  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb) return;
    tz.initializeTimeZones();
    try {
      final String timeZoneName = tz.local.name;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print("Local timezone configured: $timeZoneName");
    } catch (e) {
      print("Error configuring local timezone: $e. Using default UTC or system's last known.");
    }
  }

  Future<void> _scheduleDailyLessonReminder() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
        print("Skipping daily reminder scheduling (not Android).");
        return;
    } 

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_lesson_reminder_channel_01',
      'Daily Lesson Reminders',
      channelDescription: 'Channel for daily lesson reminders to keep you on track.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    print("Attempting to schedule daily lesson reminder for Android...");
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
          0,
          'Час для уроку в Lychakingo!',
          'Ваш щоденний урок чекає на вас. Не пропустіть!',
          _nextInstanceOfNineAM(),
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,     
          matchDateTimeComponents: DateTimeComponents.time,
          payload: '/lesson_list_screen'
          );
      print("Daily lesson reminder scheduled for next 9 AM local time on Android.");
    } catch (e) {
      print("Error scheduling daily reminder: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error scheduling reminder: $e"))
        );
      }
    }
  }

  tz.TZDateTime _nextInstanceOfNineAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    print("Next 9 AM instance is: $scheduledDate for timezone ${tz.local.name}");
    return scheduledDate;
  }

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    AiQaScreen(),
    TranslationScreen(),
    LessonListScreen(),
  ];

   static const List<String> _appBarTitles = <String>[
    'Головна',
    'ШІ Асистент',
    'Перекладач',
    'Уроки',
  ];

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
  }

  Future<void> _signOut(BuildContext context) async {
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
       Navigator.of(context).pop();
    }
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully logged out!')),
        );
      }
    } catch (e) {
      print('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  Widget _buildEndDrawer(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    accountName: null,
                    accountEmail: Text(
                        currentUser?.email ?? "Not logged in",
                        style: TextStyle(color: colorScheme.onPrimary),
                    ),
                    currentAccountPicture: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blueGrey.shade700,
                      child: const Icon(
                          Icons.person_outline,
                          size: 35,
                          color: Colors.white,
                       ),
                    ),
                    decoration: BoxDecoration(
                       color: colorScheme.primary,
                    ),
                    margin: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Вийти'),
              onTap: () {
                _signOut(context);
              },
            ),
             SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
       ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
      title: Text(_appBarTitles[_selectedIndex]),
         automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Меню',
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: _buildEndDrawer(context),
      body: IndexedStack(
         index: _selectedIndex,
         children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
           BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Головна'),
           BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'ШІ асистент'),
           BottomNavigationBarItem(icon: Icon(Icons.translate_outlined), activeIcon: Icon(Icons.translate), label: 'Перекладач'),
           BottomNavigationBarItem(icon: Icon(Icons.school_outlined), activeIcon: Icon(Icons.school), label: 'Уроки'),
        ],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}