package com.example.nl

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.graphics.drawable.Drawable
import android.graphics.Bitmap
import android.graphics.Canvas
import java.io.ByteArrayOutputStream
import android.util.Base64
import android.util.Log
import android.app.NotificationManager
import android.content.ComponentName
import android.os.Handler
import android.os.Looper
import org.json.JSONArray

class NotificationPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware {
    
    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var activity: Activity? = null
    private var notificationService: NotificationService? = null
    
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        
        // 设置方法通道
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "notification_plugin")
        methodChannel.setMethodCallHandler(this)
        
        // 设置事件通道
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "notification_events")
        eventChannel.setStreamHandler(this)
    }
    
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
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
            
            "getInstalledApps" -> {
                getInstalledApps(result)
            }
            
            "setSelectedApps" -> {
                val selectedApps = call.arguments as? List<String>
                if (selectedApps != null) {
                    NotificationService.setSelectedApps(selectedApps)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENTS", "需要有效的应用包名列表", null)
                }
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

    // 实现 ActivityAware 接口的方法
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private fun getInstalledApps(result: Result) {
        Thread {
            try {
                val packageManager = context.packageManager
                val installedApps = ArrayList<Map<String, Any>>()
                
                val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    packageManager.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(0))
                } else {
                    packageManager.getInstalledApplications(0)
                }
                
                for (packageInfo in packages) {
                    try {
                        // 只获取用户应用，排除系统应用
                        if ((packageInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0) {
                            val appName = packageManager.getApplicationLabel(packageInfo).toString()
                            val packageName = packageInfo.packageName
                            
                            try {
                                val appIcon = packageManager.getApplicationIcon(packageInfo)
                                // 将图标转换为Base64字符串
                                val iconBase64 = drawableToBase64(appIcon)
                                
                                val appInfo = HashMap<String, Any>()
                                appInfo["appName"] = appName
                                appInfo["packageName"] = packageName
                                appInfo["appIcon"] = iconBase64
                                
                                installedApps.add(appInfo)
                            } catch (e: Exception) {
                                // 如果获取图标失败，添加没有图标的应用信息
                                Log.e("NotificationPlugin", "获取应用图标失败: ${packageName}", e)
                                val appInfo = HashMap<String, Any>()
                                appInfo["appName"] = appName
                                appInfo["packageName"] = packageName
                                appInfo["appIcon"] = "" // 空图标
                                
                                installedApps.add(appInfo)
                            }
                        }
                    } catch (e: Exception) {
                        // 忽略单个应用处理错误，继续处理下一个
                        Log.e("NotificationPlugin", "处理应用信息失败", e)
                    }
                }
                
                // 按应用名称排序
                installedApps.sortBy { it["appName"] as String }
                
                // 确保在主线程中回调
                Handler(Looper.getMainLooper()).post {
                    result.success(installedApps)
                }
            } catch (e: Exception) {
                Log.e("NotificationPlugin", "获取应用列表失败", e)
                Handler(Looper.getMainLooper()).post {
                    result.error("GET_APPS_ERROR", e.message, null)
                }
            }
        }.start()
    }
    
    private fun drawableToBase64(drawable: Drawable): String {
        var bitmap: Bitmap? = null
        var byteArrayOutputStream: ByteArrayOutputStream? = null
        
        try {
            // 限制图标大小，避免内存问题
            val maxSize = 96 // 图标的最大尺寸
            val width = Math.min(drawable.intrinsicWidth, maxSize)
            val height = Math.min(drawable.intrinsicHeight, maxSize)
            
            bitmap = Bitmap.createBitmap(
                if (width <= 0) maxSize else width,
                if (height <= 0) maxSize else height,
                Bitmap.Config.ARGB_8888
            )
            
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            
            byteArrayOutputStream = ByteArrayOutputStream()
            // 使用较低的压缩质量减小数据大小
            bitmap.compress(Bitmap.CompressFormat.PNG, 80, byteArrayOutputStream)
            val byteArray = byteArrayOutputStream.toByteArray()
            // 使用NO_WRAP标志避免产生换行符
            return Base64.encodeToString(byteArray, Base64.NO_WRAP)
        } catch (e: Exception) {
            Log.e("NotificationPlugin", "转换图标失败", e)
            return ""
        } finally {
            // 释放资源
            bitmap?.recycle()
            try {
                byteArrayOutputStream?.close()
            } catch (e: Exception) {
                Log.e("NotificationPlugin", "关闭流失败", e)
            }
        }
    }
} 