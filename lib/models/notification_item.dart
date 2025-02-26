class NotificationItem {
  final int id;
  final String key;
  final String title;
  final String text;
  final String packageName;
  final String appName;
  final int postTime;
  final bool isClearable;
  final String eventType;

  NotificationItem({
    required this.id,
    required this.key,
    required this.title,
    required this.text,
    required this.packageName,
    required this.appName,
    required this.postTime,
    required this.isClearable,
    required this.eventType,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      key: json['key'],
      title: json['title'] ?? '',
      text: json['text'] ?? '',
      packageName: json['packageName'] ?? '',
      appName: json['appName'] ?? '',
      postTime: json['postTime'] ?? 0,
      isClearable: json['isClearable'] ?? false,
      eventType: json['eventType'] ?? '',
    );
  }

  // 用于通知去重和更新
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationItem && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
} 