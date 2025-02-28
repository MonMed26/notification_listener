import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../utils/date_formatter.dart';

enum NotificationCardStyle {
  compact, // 小型卡片
  large, // 大型卡片
}

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final bool showDeleteButton;
  final Function()? onDelete;
  final Function()? onTap;
  final NotificationCardStyle cardStyle;

  const NotificationCard({
    Key? key,
    required this.notification,
    this.showDeleteButton = true,
    this.onDelete,
    this.onTap,
    this.cardStyle = NotificationCardStyle.compact,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return cardStyle == NotificationCardStyle.compact
        ? _buildCompactCard(context)
        : _buildLargeCard(context);
  }

  // 小型卡片 (原有样式)
  Widget _buildCompactCard(BuildContext context) {
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
              '时间: ${DateFormatter.formatTime(notification.postTime)}',
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

  // 大型卡片 (新样式)
  Widget _buildLargeCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    radius: 24,
                    child: Text(
                      notification.appName.isNotEmpty
                          ? notification.appName[0]
                          : '?',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.appName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          notification.title.isNotEmpty
                              ? notification.title
                              : '无标题',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (showDeleteButton)
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                notification.text.isNotEmpty ? notification.text : '无内容',
                style: TextStyle(fontSize: 16),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _getRelativeTime(notification.postTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 相对时间显示 (如 "5分钟前")
  String _getRelativeTime(int timestamp) {
    final now = DateTime.now();
    final notificationTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(notificationTime);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else {
      return DateFormatter.formatTime(timestamp);
    }
  }
}
