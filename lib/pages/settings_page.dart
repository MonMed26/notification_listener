import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/app_service.dart';
import '../services/permission_service.dart';
import '../services/settings_service.dart';
import '../utils/permission_helper.dart';
import '../models/notification_item.dart';
import '../widgets/notification_card.dart';
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
  final SettingsService _settingsService = SettingsService();
  bool _hasPermission = false;
  bool _isLoading = true;
  List<String> _selectedApps = [];
  double _cardSizeScale = 1.0;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _loadSelectedApps();
    _loadCardSize();
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

  Future<void> _loadCardSize() async {
    try {
      final size = await _settingsService.getCardSize();
      setState(() {
        _cardSizeScale = size;
      });
    } catch (e) {
      print('加载卡片大小设置失败: $e');
    }
  }

  Future<void> _saveCardSize(double size) async {
    try {
      await _settingsService.saveCardSize(size);
      setState(() {
        _cardSizeScale = size;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('卡片大小设置已保存')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存卡片大小设置失败: $e')));
    }
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
                  _buildAppSelectionSection(),
                  Divider(),
                  _buildCardSizeSection(),
                  Divider(),
                  _buildAboutSection(),
                ],
              ),
    );
  }

  Widget _buildCardSizeSection() {
    final previewNotification = NotificationItem(
      id: 0,
      key: 'preview-notification',
      packageName: 'com.example.app',
      appName: '示例应用',
      title: '示例通知标题',
      text: '这是一个用于展示大型卡片缩放效果的示例通知内容。您可以通过下方的滑块调整卡片大小。',
      postTime: DateTime.now().millisecondsSinceEpoch,
      isClearable: true,
      eventType: 'POSTED',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '卡片大小设置',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('调整大型卡片的显示大小', style: TextStyle(color: Colors.grey[600])),
        ),
        Slider(
          value: _cardSizeScale,
          min: 0.7,
          max: 3,
          divisions: 6,
          label: _cardSizeScale.toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              _cardSizeScale = value;
            });
          },
          onChangeEnd: (value) {
            _saveCardSize(value);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('小', style: TextStyle(color: Colors.grey[600])),
              Text('标准', style: TextStyle(color: Colors.grey[600])),
              Text('大', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '预览效果：',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              NotificationCard(
                notification: previewNotification,
                cardStyle: NotificationCardStyle.large,
                sizeScale: _cardSizeScale,
                onTap: () {},
                showDeleteButton: false,
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildAppSelectionSection() {
    return ListTile(
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
