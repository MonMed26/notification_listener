import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';
import '../services/app_service.dart';
import '../widgets/notification_card.dart';
import '../widgets/empty_notification_view.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

class NotificationListPage extends StatefulWidget {
  @override
  _NotificationListPageState createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage>
    with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  final AppService _appService = AppService();
  StreamSubscription? _notificationSubscription;
  List<NotificationItem> _notifications = [];
  List<NotificationItem> _filteredNotifications = [];
  bool _hasPermission = false;
  bool _hasNotificationPermission = false;

  // 初始化为当天日期
  DateTime _todayStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 设置今天的开始时间（凌晨）
    _todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // 启动后自动请求通知权限
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermission();
    });

    _initializeNotificationService();
  }

  // 请求通知权限
  Future<void> _requestNotificationPermission() async {
    try {
      // 检查通知权限状态
      final status = await Permission.notification.status;
      setState(() {
        _hasNotificationPermission = status.isGranted;
      });

      // 如果没有权限，则请求
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        setState(() {
          _hasNotificationPermission = result.isGranted;
        });
      }

      // 如果获得了通知权限，并且还没有通知监听服务权限，则提示用户去设置
      if (_hasNotificationPermission && !_hasPermission) {
        // 使用延迟，确保UI已完全加载
        Future.delayed(Duration(milliseconds: 500), () {
          _openSettings();
        });
      }
    } catch (e) {
      print('请求通知权限时出错: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用回到前台，刷新通知状态
      _checkPermissionAndInitialize();

      // 检查通知权限
      Permission.notification.status.then((status) {
        setState(() {
          _hasNotificationPermission = status.isGranted;
        });
      });
    } else if (state == AppLifecycleState.paused) {
      // 应用进入后台，确保数据保存
      if (_hasPermission) {
        // 无需额外操作，通知服务已在变更时保存数据
      }
    }
  }

  void _applyTodayFilter() {
    final DateTime todayEnd = _todayStart.add(Duration(days: 1));

    _filteredNotifications =
        _notifications.where((notification) {
          final notificationDate = DateTime.fromMillisecondsSinceEpoch(
            notification.postTime,
          );
          return notificationDate.isAfter(_todayStart) &&
              notificationDate.isBefore(todayEnd);
        }).toList();
  }

  Future<void> _initializeNotificationService() async {
    await _checkPermissionAndInitialize();

    // 同步选中的应用到原生端
    await _appService.syncSelectedAppsToNative();

    // 监听新通知
    _notificationSubscription = _notificationService.notificationStream.listen((
      notification,
    ) {
      setState(() {
        _notifications = List.from(_notificationService.notifications)
          ..sort((a, b) => b.postTime.compareTo(a.postTime));
        _applyTodayFilter();
      });
    });
  }

  Future<void> _checkPermissionAndInitialize() async {
    final hasPermission =
        await _notificationService.isNotificationServiceEnabled();

    setState(() {
      _hasPermission = hasPermission;
    });

    if (hasPermission) {
      await _notificationService.init();
      setState(() {
        _notifications = List.from(_notificationService.notifications)
          ..sort((a, b) => b.postTime.compareTo(a.postTime));
        _applyTodayFilter();
      });
    }
  }

  // 导航到统计页面
  void _navigateToStatistics() {
    Navigator.pushNamed(context, '/statistics');
  }

  // 导航到设置页面
  void _navigateToSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('今日通知'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _checkPermissionAndInitialize,
          ),
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: _navigateToStatistics,
            tooltip: '查看统计',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: '设置',
          ),
        ],
      ),
      body:
          !_hasPermission
              ? _buildPermissionRequest()
              : _buildNotificationList(),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '需要通知访问权限',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '请点击下方按钮，然后在系统设置中启用通知访问权限',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          if (!_hasNotificationPermission)
            Text(
              '请允许应用发送通知，以便接收系统通知',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.orange[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_hasNotificationPermission)
                ElevatedButton(
                  onPressed: _requestNotificationPermission,
                  child: Text('请求通知权限'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              SizedBox(width: 16),
              ElevatedButton(onPressed: _openSettings, child: Text('打开通知监听设置')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    if (_filteredNotifications.isEmpty) {
      return EmptyNotificationView(message: '今日暂无通知');
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '今日通知（${_filteredNotifications.length}）',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                icon: Icon(Icons.bar_chart),
                label: Text('查看所有统计'),
                onPressed: _navigateToStatistics,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredNotifications.length,
            itemBuilder: (context, index) {
              final notification = _filteredNotifications[index];
              return NotificationCard(
                notification: notification,
                showDeleteButton: false, // 不显示删除按钮
                cardStyle: NotificationCardStyle.large, // 使用大型卡片样式
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openSettings() async {
    await _notificationService.openNotificationSettings();
  }
}
