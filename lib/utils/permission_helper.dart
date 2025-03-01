import 'package:flutter/material.dart';
import '../services/permission_service.dart';

/// 权限辅助类，提供常用的权限相关UI和实用功能
class PermissionHelper {
  static final PermissionService _permissionService = PermissionService();

  /// 显示权限请求对话框
  static Future<void> showPermissionRequestDialog(
    BuildContext context, {
    String title = '需要权限',
    String content = '请授予应用所需的权限以继续使用',
    String confirmText = '去设置',
    String cancelText = '取消',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onCancel != null) onCancel();
                },
                child: Text(cancelText),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onConfirm != null) {
                    onConfirm();
                  } else {
                    _permissionService.openNotificationServiceSettings();
                  }
                },
                child: Text(confirmText),
              ),
            ],
          ),
    );
  }

  /// 检查是否有所有必需的权限，如果没有则显示对话框
  static Future<bool> checkAndShowPermissionDialog(
    BuildContext context, {
    bool showDialog = true,
  }) async {
    final permissions =
        await _permissionService.checkAndRequestAllPermissions();

    final hasAllPermissions = permissions.values.every(
      (hasPermission) => hasPermission,
    );

    if (!hasAllPermissions && showDialog) {
      await showPermissionRequestDialog(
        context,
        title: '权限缺失',
        content: '应用需要通知权限和通知监听服务权限才能正常工作',
        confirmText: '去设置',
        onConfirm: () => _permissionService.openNotificationServiceSettings(),
      );
    }

    return hasAllPermissions;
  }

  /// 检查特定权限并显示友好的提示
  static Future<void> checkSpecificPermission(
    BuildContext context,
    String permissionType,
  ) async {
    bool hasPermission = false;
    String permissionName = '';

    switch (permissionType) {
      case 'notification':
        hasPermission = await _permissionService.hasNotificationPermission();
        permissionName = '通知权限';
        break;
      case 'notificationService':
        hasPermission = await _permissionService.isNotificationServiceEnabled();
        permissionName = '通知监听服务权限';
        break;
      default:
        return;
    }

    if (!hasPermission) {
      await showPermissionRequestDialog(
        context,
        title: '需要$permissionName',
        content: '应用需要$permissionName才能正常工作',
        confirmText: '去设置',
        onConfirm: () {
          if (permissionType == 'notification') {
            _permissionService.requestNotificationPermission();
          } else if (permissionType == 'notificationService') {
            _permissionService.openNotificationServiceSettings();
          }
        },
      );
    }
  }

  /// 构建权限请求UI
  static Widget buildPermissionRequestView({
    required bool hasNotificationPermission,
    required bool hasNotificationServicePermission,
    required VoidCallback onRequestPermission,
    required VoidCallback onOpenSettings,
  }) {
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
          if (!hasNotificationPermission)
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
              if (!hasNotificationPermission)
                ElevatedButton(
                  onPressed: onRequestPermission,
                  child: Text('请求通知权限'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: onOpenSettings,
                child: Text('打开通知监听设置'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
