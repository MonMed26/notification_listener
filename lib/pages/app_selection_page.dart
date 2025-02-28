import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/app_info.dart';
import '../services/app_service.dart';

class AppSelectionPage extends StatefulWidget {
  const AppSelectionPage({Key? key}) : super(key: key);

  @override
  _AppSelectionPageState createState() => _AppSelectionPageState();
}

class _AppSelectionPageState extends State<AppSelectionPage> {
  final AppService _appService = AppService();
  List<AppInfo> _appList = [];
  List<AppInfo> _filteredAppList = [];
  Set<String> _selectedApps = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取已安装的应用列表
      final apps = await _appService.getInstalledApps();

      // 获取已选择的应用
      final selectedApps = await _appService.getSelectedApps();

      setState(() {
        _appList = apps;
        _filteredAppList = List.from(_appList);
        _selectedApps = Set.from(selectedApps);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载应用列表失败: $e')));
      }
    }
  }

  void _filterApps(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAppList = List.from(_appList);
      } else {
        _filteredAppList =
            _appList
                .where(
                  (app) =>
                      app.appName.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  void _saveSelectedApps() async {
    try {
      await _appService.saveSelectedApps(_selectedApps.toList());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已保存选择的应用')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  // 安全解码Base64图标
  Widget _safeImageFromBase64(String base64String) {
    if (base64String.isEmpty) {
      return const Icon(Icons.android, size: 40);
    }

    try {
      // 尝试清理Base64字符串，移除可能的空白字符
      final cleanedBase64 = base64String.trim().replaceAll(RegExp(r'\s+'), '');
      return Image.memory(
        base64Decode(cleanedBase64),
        width: 40,
        height: 40,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.android, size: 40);
        },
      );
    } catch (e) {
      // 解码失败时显示默认图标
      return const Icon(Icons.android, size: 40);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择应用'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSelectedApps,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: '搜索应用',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterApps,
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredAppList.isEmpty
                    ? const Center(child: Text('没有找到匹配的应用'))
                    : ListView.builder(
                      itemCount: _filteredAppList.length,
                      itemBuilder: (context, index) {
                        final app = _filteredAppList[index];
                        final isSelected = _selectedApps.contains(
                          app.packageName,
                        );

                        return ListTile(
                          leading: _safeImageFromBase64(app.appIcon),
                          title: Text(app.appName),
                          subtitle: Text(app.packageName),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedApps.add(app.packageName);
                                } else {
                                  _selectedApps.remove(app.packageName);
                                }
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedApps.remove(app.packageName);
                              } else {
                                _selectedApps.add(app.packageName);
                              }
                            });
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
