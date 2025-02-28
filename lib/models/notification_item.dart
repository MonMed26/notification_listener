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

  // 使用 postTime + id 作为主键来判断通知唯一性
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationItem && 
           other.id == id && 
           other.postTime == postTime;
  }

  @override
  int get hashCode => postTime.hashCode ^ id.hashCode;
  
  // 获取通知的唯一标识符
  String get uniqueId => '${postTime}_$id';
} 