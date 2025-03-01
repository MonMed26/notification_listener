import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/app_service.dart';
import '../services/permission_service.dart';
import '../utils/permission_helper.dart';
import 'app_selection_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final NotificationService _notificationService = NotificationService();
  final AppService _appService = AppService();
  final PermissionService _permissionService = PermissionService();
  bool _hasPermission = false;
  bool _isLoading = true;
  List<String> _selectedApps = [];

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _loadSelectedApps();
  }

  Future<void> _checkPermission() async {
    final hasPermission =
        await _permissionService.isNotificationServiceEnabled();

    setState(() {
      _hasPermission = hasPermission;
      _isLoading = false;
    });
  }

  Future<void> _openSettings() async {
    await _permissionService.openNotificationServiceSettings();
  }

  Future<void> _loadSelectedApps() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final selectedApps = await _appService.getSelectedApps();
      setState(() {
        _selectedApps = selectedApps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载已选应用失败: $e')));
    }
  }

  void _openAppSelectionPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AppSelectionPage()),
    );
    // 返回后重新加载已选应用
    _loadSelectedApps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('设置')),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  _buildPermissionSection(),
                  Divider(),
                  _buildAboutSection(),
                  ListTile(
                    title: const Text('选择需要读取通知的应用'),
                    subtitle:
                        _isLoading
                            ? const Text('加载中...')
                            : Text(
                              _selectedApps.isEmpty
                                  ? '未选择任何应用'
                                  : '已选择 ${_selectedApps.length} 个应用',
                            ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _openAppSelectionPage,
                  ),
                ],
              ),
    );
  }

  Widget _buildPermissionSection() {
    return ListTile(
      title: Text('通知监听权限'),
      subtitle: Text(_hasPermission ? '已授权' : '未授权'),
      leading: Icon(
        _hasPermission ? Icons.notifications_active : Icons.notifications_off,
        color: _hasPermission ? Colors.green : Colors.red,
      ),
      trailing: TextButton(
        onPressed: () {
          _permissionService.openNotificationServiceSettings();
        },
        child: Text('打开设置'),
      ),
      onTap: _checkPermission,
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '关于',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        ListTile(
          title: Text('通知监听器'),
          subtitle: Text('版本 1.0.0'),
          leading: Icon(Icons.info_outline),
        ),
        ListTile(
          title: Text('使用说明'),
          subtitle: Text('本应用需要通知访问权限才能读取系统通知'),
          leading: Icon(Icons.help_outline),
        ),
      ],
    );
  }
}
