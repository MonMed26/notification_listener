import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';
import '../widgets/notification_card.dart';
import '../widgets/empty_notification_view.dart';
import '../widgets/confirm_dialog.dart';
import '../utils/date_formatter.dart';
import 'dart:async';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationItem> _notifications = [];
  List<NotificationItem> _filteredNotifications = [];

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFilterActive = false;

  // 添加应用筛选相关变量
  String? _selectedApp;
  List<String> _availableApps = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _notifications = List.from(_notificationService.notifications)
        ..sort((a, b) => b.postTime.compareTo(a.postTime));
      _applyDateFilter();
    });
    _updateAvailableApps();
  }

  void _applyDateFilter() {
    if ((!_isFilterActive || (_startDate == null && _endDate == null)) &&
        _selectedApp == null) {
      _filteredNotifications = List.from(_notifications);
      return;
    }

    _filteredNotifications =
        _notifications.where((notification) {
          bool matchesDateFilter = true;
          bool matchesAppFilter = true;

          // 应用日期筛选
          if (_isFilterActive && (_startDate != null || _endDate != null)) {
            final notificationDate = DateTime.fromMillisecondsSinceEpoch(
              notification.postTime,
            );

            if (_startDate != null) {
              final start = DateTime(
                _startDate!.year,
                _startDate!.month,
                _startDate!.day,
              );
              if (notificationDate.isBefore(start)) {
                matchesDateFilter = false;
              }
            }

            if (_endDate != null) {
              final end = DateTime(
                _endDate!.year,
                _endDate!.month,
                _endDate!.day,
                23,
                59,
                59,
              );
              if (notificationDate.isAfter(end)) {
                matchesDateFilter = false;
              }
            }
          }

          // 应用应用名称筛选
          if (_selectedApp != null) {
            matchesAppFilter = notification.appName == _selectedApp;
          }

          return matchesDateFilter && matchesAppFilter;
        }).toList();
  }

  // 更新可用的应用列表
  void _updateAvailableApps() {
    final Set<String> apps =
        _notifications.map((n) => n.appName).toSet()
          ..removeWhere((app) => app.isEmpty);
    _availableApps = apps.toList()..sort();
  }

  // 选择应用进行筛选
  void _selectApp(String? appName) {
    setState(() {
      _selectedApp = appName;
      _applyDateFilter();
    });
  }

  void _resetFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedApp = null;
      _isFilterActive = false;
      _filteredNotifications = List.from(_notifications);
    });
  }

  Future<void> _selectDateRange() async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(Duration(days: 7)),
      end: _endDate ?? DateTime.now(),
    );

    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Theme.of(context).primaryColor,
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDateRange != null) {
      setState(() {
        _startDate = pickedDateRange.start;
        _endDate = pickedDateRange.end;
        _isFilterActive = true;
        _applyDateFilter();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('通知统计'),
        actions: [
          // 添加应用筛选下拉菜单
          IconButton(
            icon: Icon(Icons.apps),
            onPressed: () {
              _showAppFilterDialog();
            },
            tooltip: '按应用筛选',
          ),
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: _selectDateRange,
            tooltip: '按日期筛选',
          ),
          if (_isFilterActive || _selectedApp != null)
            IconButton(
              icon: Icon(Icons.filter_alt_off),
              onPressed: _resetFilter,
              tooltip: '清除筛选',
            ),
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadNotifications),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep),
              onPressed: _showClearConfirmDialog,
            ),
        ],
      ),
      body: _buildStatisticsView(),
    );
  }

  Widget _buildStatisticsView() {
    // 构建筛选信息
    Widget filterInfo = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isFilterActive)
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '日期筛选: ${DateFormatter.formatDate(_startDate)} 至 ${DateFormatter.formatDate(_endDate)}',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                      _isFilterActive = false;
                      _applyDateFilter();
                    });
                  },
                  child: Text('清除'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        if (_selectedApp != null)
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '应用筛选: $_selectedApp',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedApp = null;
                      _applyDateFilter();
                    });
                  },
                  child: Text('清除'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (_filteredNotifications.isEmpty) {
      return Column(
        children: [
          if (_isFilterActive || _selectedApp != null) filterInfo,
          Expanded(
            child: EmptyNotificationView(
              message:
                  _isFilterActive || _selectedApp != null
                      ? '筛选条件下暂无通知'
                      : '暂无通知',
            ),
          ),
        ],
      );
    }

    // 按应用分组统计
    Map<String, int> appStats = {};
    for (var notification in _filteredNotifications) {
      if (notification.appName.isNotEmpty) {
        appStats[notification.appName] =
            (appStats[notification.appName] ?? 0) + 1;
      }
    }

    List<MapEntry<String, int>> sortedStats =
        appStats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        if (_isFilterActive || _selectedApp != null) filterInfo,
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '通知总数: ${_filteredNotifications.length}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  '按应用统计',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedStats.length,
                  itemBuilder: (context, index) {
                    final app = sortedStats[index].key;
                    final count = sortedStats[index].value;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          app.isNotEmpty ? app[0] : '?',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(app),
                      trailing: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        _selectApp(app);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    _showNotificationsList();
                  },
                  child: Text('查看通知列表'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showNotificationsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '通知列表',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
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
                          return await ConfirmDialog.show(
                            context: context,
                            title: '删除通知',
                            content: '确定要删除这条通知记录吗？',
                          );
                        },
                        onDismissed: (direction) {
                          _notificationService.deleteNotification(
                            notification.uniqueId,
                          );
                          setState(() {
                            _filteredNotifications.removeAt(index);
                            _notifications.remove(notification);
                          });
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('通知已删除')));
                        },
                        child: NotificationCard(
                          notification: notification,
                          showDeleteButton: true,
                          cardStyle: NotificationCardStyle.compact,
                          onDelete: () async {
                            final confirmed = await ConfirmDialog.show(
                              context: context,
                              title: '删除通知',
                              content: '确定要删除这条通知记录吗？',
                            );

                            if (confirmed == true) {
                              _notificationService.deleteNotification(
                                notification.uniqueId,
                              );
                              setState(() {
                                _filteredNotifications.removeAt(index);
                                _notifications.remove(notification);
                              });
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text('通知已删除')));
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showClearConfirmDialog() async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: '清空所有通知',
      content: '确定要清空所有通知记录吗？此操作不可撤销。',
      isDanger: true,
    );

    if (confirmed == true) {
      _notificationService.clearNotifications();
      setState(() {
        _notifications.clear();
        _filteredNotifications.clear();
      });
    }
  }

  // 显示应用筛选对话框
  Future<void> _showAppFilterDialog() async {
    _updateAvailableApps();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('按应用筛选'),
            content: Container(
              width: double.maxFinite,
              child:
                  _availableApps.isEmpty
                      ? Text('没有可用的应用')
                      : ListView(
                        shrinkWrap: true,
                        children: [
                          // 添加"全部应用"选项
                          ListTile(
                            title: Text('全部应用'),
                            selected: _selectedApp == null,
                            onTap: () {
                              _selectApp(null);
                              Navigator.of(context).pop();
                            },
                          ),
                          Divider(),
                          ..._availableApps.map(
                            (app) => ListTile(
                              title: Text(app),
                              selected: _selectedApp == app,
                              onTap: () {
                                _selectApp(app);
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('取消'),
              ),
            ],
          ),
    );
  }
}
