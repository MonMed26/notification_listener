import 'package:flutter/material.dart';
import '../models/notification_item.dart';

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final bool showDeleteButton;
  final Function()? onDelete;
  final Function()? onTap;

  const NotificationCard({
    Key? key,
    required this.notification,
    this.showDeleteButton = true,
    this.onDelete,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            notification.appName.isNotEmpty ? notification.appName[0] : '?',
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          notification.title.isNotEmpty ? notification.title : '无标题',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.text.isNotEmpty ? notification.text : '无内容'),
            SizedBox(height: 4),
            Text(
              '应用: ${notification.appName}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              '时间: ${formatTime(notification.postTime)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        isThreeLine: true,
        trailing:
            showDeleteButton
                ? IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: onDelete,
                )
                : null,
      ),
    );
  }

  // 格式化时间方法
  static String formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
}
