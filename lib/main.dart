import 'package:flutter/material.dart';
import 'pages/notification_list_page.dart';
import 'pages/statistics_page.dart';
import 'pages/settings_page.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 请求通知权限
  await Permission.notification.request();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '通知监听器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => NotificationListPage(),
        '/statistics': (context) => StatisticsPage(),
        '/settings': (context) => SettingsPage(),
      },
    );
  }
}
