import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final NotificationService _notificationService = NotificationService();
  bool _hasPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission =
        await _notificationService.isNotificationServiceEnabled();

    setState(() {
      _hasPermission = hasPermission;
      _isLoading = false;
    });
  }

  Future<void> _openSettings() async {
    await _notificationService.openNotificationSettings();
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
      trailing: TextButton(onPressed: _openSettings, child: Text('打开设置')),
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
