import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // 单例模式
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // 检查通知权限状态
  Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // 请求通知权限
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // 检查并请求通知权限
  Future<bool> checkAndRequestNotificationPermission() async {
    // 先检查权限状态
    final hasPermission = await checkNotificationPermission();

    // 如果已有权限，直接返回
    if (hasPermission) {
      return true;
    }

    // 没有权限，尝试请求
    return await requestNotificationPermission();
  }

  // 打开应用设置页面
  // Future<bool> openAppSettings() async {
  //   return await Permission.openAppSettings();
  // }
}
