class AppInfo {
  final String appName;
  final String packageName;
  final String appIcon; // Base64编码的图标

  AppInfo({
    required this.appName,
    required this.packageName,
    required this.appIcon,
  });

  factory AppInfo.fromMap(Map map) {
    return AppInfo(
      appName: map['appName']?.toString() ?? '',
      packageName: map['packageName']?.toString() ?? '',
      appIcon: map['appIcon']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'appName': appName, 'packageName': packageName, 'appIcon': appIcon};
  }
}
