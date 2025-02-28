import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';
import 'dart:async';

class NotificationListPage extends StatefulWidget {
  @override
  _NotificationListPageState createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage>
    with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _notificationSubscription;
  List<NotificationItem> _notifications = [];
  List<NotificationItem> _filteredNotifications = [];
  bool _hasPermission = false;

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
    _initializeNotificationService();
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
          SizedBox(height: 24),
          ElevatedButton(onPressed: _openSettings, child: Text('打开设置')),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    if (_filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '今日暂无通知',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
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
              return Dismissible(
                key: Key(notification.uniqueId),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('删除通知'),
                          content: Text('确定要删除这条通知记录吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('确定'),
                            ),
                          ],
                        ),
                  );
                },
                onDismissed: (direction) {
                  _notificationService.deleteNotification(
                    notification.uniqueId,
                  );
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('通知已删除')));
                },
                child: Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        notification.appName.isNotEmpty
                            ? notification.appName[0]
                            : '?',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      notification.title.isNotEmpty
                          ? notification.title
                          : '无标题',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.text.isNotEmpty
                              ? notification.text
                              : '无内容',
                        ),
                        SizedBox(height: 4),
                        Text(
                          '应用: ${notification.appName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '时间: ${_formatTime(notification.postTime)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text('删除通知'),
                                content: Text('确定要删除这条通知记录吗？'),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    child: Text('确定'),
                                  ),
                                ],
                              ),
                        );

                        if (confirmed == true) {
                          _notificationService.deleteNotification(
                            notification.uniqueId,
                          );
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('通知已删除')));
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  Future<void> _openSettings() async {
    await _notificationService.openNotificationSettings();
  }
}
