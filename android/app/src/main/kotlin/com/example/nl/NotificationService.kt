package com.example.nl

import android.app.Notification
import android.content.pm.PackageManager
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.EventChannel
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import androidx.core.app.NotificationCompat

class NotificationService : NotificationListenerService() {
    
    companion object {
        private const val TAG = "NotificationService"
        private var eventSink: EventChannel.EventSink? = null
        
        // 通知渠道ID
        private const val CHANNEL_ID = "nl_system_notification_channel"
        // 系统通知ID
        private const val SYSTEM_NOTIFICATION_ID = 1001
        
        fun setEventSink(sink: EventChannel.EventSink?) {
            eventSink = sink
        }
        
        // 保存通知列表，用于 Flutter 端查询
        private val notificationList = mutableListOf<JSONObject>()
        
        // 保存用户选择的应用包名列表
        private val selectedApps = mutableListOf<String>()
        
        fun setSelectedApps(packageNames: List<String>) {
            synchronized(selectedApps) {
                selectedApps.clear()
                selectedApps.addAll(packageNames)
                Log.d(TAG, "已设置选中的应用列表: $selectedApps")
            }
        }
        
        // 检查应用是否被选中
        fun isAppSelected(packageName: String): Boolean {
            synchronized(selectedApps) {
                // 如果选中列表为空，则默认接收所有应用的通知
                return selectedApps.isEmpty() || selectedApps.contains(packageName)
            }
        }
        
        fun getAllNotifications(): List<JSONObject> {
            return notificationList
        }
        
        fun deleteNotification(id: Int, postTime: Long) {
            synchronized(notificationList) {
                notificationList.removeAll { 
                    it.getInt("id") == id && it.getLong("postTime") == postTime 
                }
            }
        }

        fun deleteAllNotifications() {
            synchronized(notificationList) {
                notificationList.clear()
            }
        }
    }
    
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        Log.d(TAG, "收到通知: ${sbn.packageName}")
        
        // 检查通知应用是否在选定列表中
        if (!isAppSelected(sbn.packageName)) {
            Log.d(TAG, "忽略非选定应用的通知: ${sbn.packageName}")
            return
        }
        
        try {
            val notification = sbn.notification
            val extras = notification.extras
            
            // 获取通知基本信息
            val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
            val packageName = sbn.packageName
            
            // 获取应用名称
            val appName = try {
                val packageManager = applicationContext.packageManager
                packageManager.getApplicationLabel(packageManager.getApplicationInfo(packageName, 0)).toString()
            } catch (e: Exception) {
                packageName
            }
            
            // 创建通知数据对象
            val notificationData = JSONObject().apply {
                put("id", sbn.id)
                // 使用 postTime_id 作为通知的 key
                put("key", "${sbn.postTime}_${sbn.id}")
                put("title", title)
                put("text", text)
                put("packageName", packageName)
                put("appName", appName)
                put("postTime", sbn.postTime)
                put("isClearable", sbn.isClearable)
                put("timestamp", System.currentTimeMillis())
                put("eventType", "posted")
            }

            // 打印通知数据
            Log.d(TAG, "通知数据: $notificationData")
            
            // 更新通知列表，使用 postTime 和 id 来确定通知的唯一性
            synchronized(notificationList) {
                // 检查是否已存在相同通知，如存在则更新
                val existingIndex = notificationList.indexOfFirst { 
                    it.getInt("id") == sbn.id && it.getLong("postTime") == sbn.postTime 
                }
                if (existingIndex >= 0) {
                    notificationList[existingIndex] = notificationData
                } else {
                    notificationList.add(notificationData)
                }
            }
            
            // 发送通知数据到 Flutter
            eventSink?.success(notificationData.toString())
            
        } catch (e: Exception) {
            Log.e(TAG, "处理通知时出错", e)
        }
    }

    // 创建通知渠道（Android 8.0及以上需要）
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "系统通知"
            val description = "通知监听服务的系统通知"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                this.description = description
                enableLights(true)
                lightColor = Color.RED
                enableVibration(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "已创建通知渠道: $CHANNEL_ID")
        }
    }
    
    // 发送系统通知
    private fun sendSystemNotification(title: String, message: String) {
        try {
            // 确保通知渠道已创建
            createNotificationChannel()
            
            // 创建打开应用的Intent
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
            )
            
            // 构建通知
            val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification) // 确保有这个图标资源
                .setContentTitle(title)
                .setContentText(message)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
            
            // 发送通知
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(SYSTEM_NOTIFICATION_ID, notificationBuilder.build())
            
            Log.d(TAG, "已发送系统通知: $title - $message")
        } catch (e: Exception) {
            Log.e(TAG, "发送系统通知时出错", e)
        }
    }

    override fun onListenerConnected() { 
        Log.d(TAG, "通知监听器已连接")
        sendSystemNotification("通知监听服务已启动", "通知监听服务已成功连接并开始工作")
    }

    override fun onListenerDisconnected() {
        Log.d(TAG, "通知监听器已断开连接")
        sendSystemNotification("通知监听服务已断开", "通知监听服务已断开连接，请检查权限设置")
    }

} 