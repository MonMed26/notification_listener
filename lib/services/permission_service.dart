import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// 统一管理应用权限的服务类
class PermissionService {
  // 单例模式
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // 用于原生通信的通道
  static const MethodChannel _channel = MethodChannel('notification_plugin');

  /// 检查应用是否有通知权限
  Future<bool> hasNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      print('检查通知权限时出错: $e');
      return false;
    }
  }

  /// 请求通知权限
  Future<bool> requestNotificationPermission() async {
    try {
      final result = await Permission.notification.request();
      return result.isGranted;
    } catch (e) {
      print('请求通知权限时出错: $e');
      return false;
    }
  }

  /// 检查通知监听服务权限
  Future<bool> isNotificationServiceEnabled() async {
    try {
      return await _channel.invokeMethod('isNotificationServiceEnabled');
    } catch (e) {
      print('检查通知监听权限时出错: $e');
      return false;
    }
  }

  /// 打开通知监听设置页面
  Future<void> openNotificationServiceSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (e) {
      print('打开通知监听设置时出错: $e');
    }
  }

  /// 检查并请求所有必需的权限
  /// 返回一个Map，包含各种权限的状态
  Future<Map<String, bool>> checkAndRequestAllPermissions() async {
    // 检查通知权限
    bool hasNotificationPerm = await hasNotificationPermission();

    // 如果没有通知权限，请求授权
    if (!hasNotificationPerm) {
      hasNotificationPerm = await requestNotificationPermission();
    }

    // 检查通知监听服务权限
    final hasNotificationServicePerm = await isNotificationServiceEnabled();

    return {
      'notificationPermission': hasNotificationPerm,
      'notificationServicePermission': hasNotificationServicePerm,
    };
  }
}
