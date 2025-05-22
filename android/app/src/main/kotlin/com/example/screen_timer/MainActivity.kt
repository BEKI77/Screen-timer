package com.example.screen_timer

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.provider.Settings
import android.util.Base64
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

data class AppUsageInfo(
        val packageName: String,
        val appName: String,
        val usageTime: Long,
        val lastTimeUsed: Long,
        val icon: String
)

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.yourapp/usage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "getRunningApps" -> {
                    val apps = getRecentAppPackages()
                    result.success(apps)
                }
                "openUsageAccess" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                "hasUsageAccess" -> {
                    result.success(isUsageAccessGranted())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getRecentAppPackages(): List<Map<String, Any?>> {
        val result = mutableListOf<Map<String, Any?>>()
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val pm = packageManager
        val time = System.currentTimeMillis()
        val appList =
                usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, time - 1000 * 60 * 10, time)

        if (appList != null) {
            val sorted = appList.sortedByDescending { it.lastTimeUsed }
            for (usageStats in sorted) {
                var appName = usageStats.packageName
                var iconBase64: String? = null

                try {
                    val appInfo = pm.getApplicationInfo(usageStats.packageName, 0)

                    if ((appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0) {
                        continue
                    }

                    val iconDrawable = pm.getApplicationIcon(appInfo)

                    // Convert icon to Base64
                    val bitmap = drawableToBitmap(iconDrawable)
                    val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                    iconBase64 = Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
                } catch (e: Exception) {
                    Log.d("MainActivity", "App not found: ${usageStats.packageName}")
                }

                result.add(
                        mapOf(
                                "packageName" to usageStats.packageName,
                                "appName" to appName,
                                "usageTime" to usageStats.totalTimeInForeground,
                                "lastTimeUsed" to usageStats.lastTimeUsed,
                                "icon" to iconBase64
                        )
                )
            }
        }
        return result
    }

    private fun isUsageAccessGranted(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager

        val mode =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    appOps.unsafeCheckOpNoThrow(
                            AppOpsManager.OPSTR_GET_USAGE_STATS,
                            android.os.Process.myUid(),
                            packageName
                    )
                } else {
                    @Suppress("DEPRECATION")
                    appOps.checkOpNoThrow(
                            AppOpsManager.OPSTR_GET_USAGE_STATS,
                            android.os.Process.myUid(),
                            packageName
                    )
                }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun drawableToBitmap(drawable: Drawable): Bitmap {
        return if (drawable is BitmapDrawable) {
            drawable.bitmap
        } else {
            val width = drawable.intrinsicWidth.takeIf { it > 0 } ?: 100
            val height = drawable.intrinsicHeight.takeIf { it > 0 } ?: 100
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bitmap
        }
    }
}
