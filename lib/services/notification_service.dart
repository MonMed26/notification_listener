import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';

class NotificationService {
  static const MethodChannel _channel = MethodChannel('notification_plugin');
  static const EventChannel _eventChannel = EventChannel('notification_events');

  // 通知流控制器
  final _notificationsController =
      StreamController<NotificationItem>.broadcast();
  Stream<NotificationItem> get notificationStream =>
      _notificationsController.stream;

  // 当前通知列表
  final List<NotificationItem> _notifications = [];
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  // 单例模式
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // 初始化服务
  Future<void> init() async {
    // 检查权限
    final hasPermission = await isNotificationServiceEnabled();
    if (!hasPermission) {
      return;
    }

    // 加载已保存的通知
    await _loadSavedNotifications();

    // 获取当前系统通知
    await _fetchCurrentNotifications();

    // 监听新通知
    _listenForNotifications();
  }

  // 检查是否有通知监听权限
  Future<bool> isNotificationServiceEnabled() async {
    try {
      return await _channel.invokeMethod('isNotificationServiceEnabled');
    } catch (e) {
      print('检查通知权限时出错: $e');
      return false;
    }
  }

  // 打开通知设置页面
  Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (e) {
      print('打开通知设置时出错: $e');
    }
  }

  // 获取当前所有通知
  Future<void> _fetchCurrentNotifications() async {
    try {
      final String notificationsJson = await _channel.invokeMethod(
        'getAllNotifications',
      );
      final List<dynamic> notificationsList = jsonDecode(notificationsJson);

      for (final item in notificationsList) {
        final notification = NotificationItem.fromJson(item);
        _updateNotificationsList(notification);
      }
    } catch (e) {
      print('获取当前通知时出错: $e');
    }
  }

  // 监听新通知
  void _listenForNotifications() {
    _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        try {
          final Map<String, dynamic> json = jsonDecode(event);
          final notification = NotificationItem.fromJson(json);

          if (notification.eventType == 'posted') {
            _updateNotificationsList(notification);
          } else if (notification.eventType == 'removed') {
            _removeNotification(notification.key);
          }

          // 发布到流
          _notificationsController.add(notification);

          // 保存通知列表
          _saveNotifications();
        } catch (e) {
          print('处理通知事件时出错: $e');
        }
      },
      onError: (dynamic error) {
        print('通知监听错误: $error');
      },
    );
  }

  // 更新通知列表
  void _updateNotificationsList(NotificationItem notification) {
    // 使用 postTime 和 id 的组合查找通知
    final index = _notifications.indexWhere(
      (n) => n.id == notification.id && n.postTime == notification.postTime,
    );
    if (index >= 0) {
      _notifications[index] = notification;
    } else {
      _notifications.add(notification);
    }
  }

  // 从列表中移除通知
  void _removeNotification(String key) {
    // 获取通知的 ID 和 postTime (如果 key 的格式是 "postTime_id")
    final parts = key.split('_');
    if (parts.length == 2) {
      try {
        final postTime = int.parse(parts[0]);
        final id = int.parse(parts[1]);
        _notifications.removeWhere((n) => n.id == id && n.postTime == postTime);
      } catch (e) {
        // 如果解析失败，回退到使用 key 删除
        _notifications.removeWhere((n) => n.key == key);
      }
    } else {
      // 向后兼容：使用 key 删除
      _notifications.removeWhere((n) => n.key == key);
    }
    _saveNotifications(); // 删除后保存更改
  }

  // 删除单个通知
  Future<void> deleteNotification(String key) async {
    // 获取通知的 ID 和 postTime (如果 key 的格式是 "postTime_id")
    final parts = key.split('_');
    if (parts.length == 2) {
      try {
        final postTime = int.parse(parts[0]);
        final id = int.parse(parts[1]);
        _notifications.removeWhere((n) => n.id == id && n.postTime == postTime);

        // 通知 Android 端删除对应通知
        await _channel.invokeMethod('deleteNotification', {
          'id': id,
          'postTime': postTime,
        });
      } catch (e) {
        // 如果解析失败，回退到使用 key 删除
        _notifications.removeWhere((n) => n.key == key);
      }
    } else {
      // 向后兼容：使用 key 删除
      _notifications.removeWhere((n) => n.key == key);
    }

    await _saveNotifications();
    // 通知流发送删除事件
    final deleteEvent = NotificationItem(
      id: 0,
      key: key,
      title: '',
      text: '',
      packageName: '',
      appName: '',
      postTime: 0,
      isClearable: true,
      eventType: 'removed',
    );
    _notificationsController.add(deleteEvent);
  }

  // 清空通知列表
  Future<void> clearNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    // 通知UI已清空
    _notificationsController.add(
      NotificationItem(
        id: 0,
        key: 'clear_all',
        title: '',
        text: '',
        packageName: '',
        appName: '',
        postTime: 0,
        isClearable: true,
        eventType: 'clear_all',
      ),
    );

    // 通知 Android 端删除所有通知
    await _channel.invokeMethod('deleteAllNotifications');
  }

  // 保存通知到本地存储
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = jsonEncode(
        _notifications
            .map(
              (n) => {
                'id': n.id,
                'key': n.key,
                'title': n.title,
                'text': n.text,
                'packageName': n.packageName,
                'appName': n.appName,
                'postTime': n.postTime,
                'isClearable': n.isClearable,
                'eventType': n.eventType,
              },
            )
            .toList(),
      );

      await prefs.setString('saved_notifications', notificationsJson);
    } catch (e) {
      print('保存通知时出错: $e');
    }
  }

  // 从本地存储加载通知
  Future<void> _loadSavedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('saved_notifications');

      if (notificationsJson != null) {
        final List<dynamic> notificationsList = jsonDecode(notificationsJson);

        _notifications.clear();
        for (final item in notificationsList) {
          _notifications.add(NotificationItem.fromJson(item));
        }
      }
    } catch (e) {
      print('加载已保存通知时出错: $e');
    }
  }

  // 关闭资源
  void dispose() {
    _notificationsController.close();
  }
}
