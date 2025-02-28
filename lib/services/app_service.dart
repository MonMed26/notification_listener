import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_info.dart';

class AppService {
  static const MethodChannel _channel = MethodChannel('notification_plugin');
  static const String _selectedAppsKey = 'selected_apps';

  // 获取已安装的应用列表
  Future<List<AppInfo>> getInstalledApps() async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod(
        'getInstalledApps',
      );

      if (result == null) {
        return [];
      }

      return result.map((app) {
        // 确保app是Map类型
        if (app is Map) {
          return AppInfo.fromMap(app);
        }
        // 如果不是Map类型，返回空的AppInfo
        return AppInfo(appName: '', packageName: '', appIcon: '');
      }).toList();
    } on PlatformException catch (e) {
      print('获取应用列表失败: ${e.message}');
      return [];
    } catch (e) {
      print('获取应用列表时发生未知错误: $e');
      return [];
    }
  }

  // 保存用户选择的应用列表
  Future<void> saveSelectedApps(List<String> packageNames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedAppsKey, packageNames);
  }

  // 获取用户选择的应用列表
  Future<List<String>> getSelectedApps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_selectedAppsKey) ?? [];
  }

  Future<void> syncSelectedAppsToNative() async {
    final selectedApps = await getSelectedApps();
    await _channel.invokeMethod('setSelectedApps', selectedApps);
  }
}
