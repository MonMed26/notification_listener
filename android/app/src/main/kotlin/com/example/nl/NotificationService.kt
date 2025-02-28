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

class NotificationService : NotificationListenerService() {
    
    companion object {
        private const val TAG = "NotificationService"
        private var eventSink: EventChannel.EventSink? = null
        
        fun setEventSink(sink: EventChannel.EventSink?) {
            eventSink = sink
        }
        
        // 保存通知列表，用于 Flutter 端查询
        private val notificationList = mutableListOf<JSONObject>()
        
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
    
    // override fun onNotificationRemoved(sbn: StatusBarNotification) {
    //     Log.d(TAG, "通知被移除: ${sbn.packageName}")
        
    //     try {
    //         // 创建通知移除事件数据
    //         val notificationData = JSONObject().apply {
    //             put("id", sbn.id)
    //             put("key", sbn.key)
    //             put("packageName", sbn.packageName)
    //             put("eventType", "removed")
    //             put("timestamp", System.currentTimeMillis())
    //         }
            
    //         // 从列表中移除通知
    //         synchronized(notificationList) {
    //             notificationList.removeAll { it.getString("key") == sbn.key }
    //         }
            
    //         // 发送通知移除事件到 Flutter
    //         eventSink?.success(notificationData.toString())
            
    //     } catch (e: Exception) {
    //         Log.e(TAG, "处理通知移除时出错", e)
    //     }
    // }
} 