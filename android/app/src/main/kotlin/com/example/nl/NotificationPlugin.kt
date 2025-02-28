package com.example.nl

import android.content.Context
import android.content.Intent
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class NotificationPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    
    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        
        // 设置方法通道
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "notification_plugin")
        methodChannel.setMethodCallHandler(this)
        
        // 设置事件通道
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "notification_events")
        eventChannel.setStreamHandler(this)
    }
    
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            // 检查是否有通知访问权限
            "isNotificationServiceEnabled" -> {
                val enabled = isNotificationServiceEnabled()
                result.success(enabled)
            }
            
            // 打开通知访问权限设置
            "openNotificationSettings" -> {
                openNotificationSettings()
                result.success(true)
            }
            
            // 获取所有当前通知
            "getAllNotifications" -> {
                val notificationList = NotificationService.getAllNotifications()
                val jsonArray = JSONArray()
                notificationList.forEach { jsonArray.put(it) }
                result.success(jsonArray.toString())
            }
            
            "deleteNotification" -> {
                val id = call.argument<Int>("id")
                val postTime = call.argument<Long>("postTime")
                if (id != null && postTime != null) {
                    NotificationService.deleteNotification(id, postTime) 
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENTS", "需要有效的id和postTime", null)
                }
            }

            "deleteAllNotifications" -> {
                NotificationService.deleteAllNotifications()
                result.success(true)
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }
    
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // 设置事件接收器
        NotificationService.setEventSink(events)
    }
    
    override fun onCancel(arguments: Any?) {
        NotificationService.setEventSink(null)
    }
    
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
    
    // 检查是否启用了通知访问权限
    private fun isNotificationServiceEnabled(): Boolean {
        val packageName = context.packageName
        val flat = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
        return flat != null && flat.contains(packageName)
    }
    
    // 打开通知访问权限设置页面
    private fun openNotificationSettings() {
        val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }
} 