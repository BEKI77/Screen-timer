package com.example.screen_timer

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

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
                "getMonthlyUsage" -> {
                    val pkgName =
                            call.argument<String>("packageName") ?: return@setMethodCallHandler
                    val resultMap = getMonthlyAppUsage(pkgName)
                    result.success(resultMap)
                }
                "getWeeklyUsage" -> {
                    val usage = getWeeklyUsage()
                    result.success(usage)
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
                var appName: String?
                var iconBase64: String? = null

                try {
                    val appInfo =
                            try {
                                pm.getApplicationInfo(usageStats.packageName, 0)
                            } catch (e: Exception) {
                                // Try with MATCH_UNINSTALLED_PACKAGES for API 24+
                                if (android.os.Build.VERSION.SDK_INT >=
                                                android.os.Build.VERSION_CODES.N
                                ) {
                                    pm.getApplicationInfo(
                                            usageStats.packageName,
                                            PackageManager.MATCH_UNINSTALLED_PACKAGES
                                    )
                                } else {
                                    throw e
                                }
                            }
                    if ((appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0) {
                        continue
                    }
                    appName = pm.getApplicationLabel(appInfo).toString()
                } catch (e: Exception) {
                    // Fallback: Try getting label from PackageInfo
                    try {
                        val pkgInfo = pm.getPackageInfo(usageStats.packageName, 0)
                        appName = pm.getApplicationLabel(pkgInfo.applicationInfo!!).toString()
                    } catch (ex: Exception) {
                        // Fallback: Extract a name from the package name
                        val parts = usageStats.packageName.split(".")
                        appName =
                                parts.lastOrNull()?.replaceFirstChar { it.uppercaseChar() }
                                        ?: usageStats.packageName
                    }
                }
                if (appName.isNullOrEmpty()) {
                    continue
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

    private fun getMonthlyAppUsage(packageName: String): Map<String, Long> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_MONTH, -30)
        val startTime = calendar.timeInMillis

        val usageStatsList =
                usageStatsManager.queryUsageStats(
                        UsageStatsManager.INTERVAL_DAILY,
                        startTime,
                        endTime
                )

        val usageMap = mutableMapOf<String, Long>() // "yyyy-MM-dd" -> totalTimeIFnForeground

        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())

        for (usageStats in usageStatsList) {
            if (usageStats.packageName == packageName) {
                val date = dateFormat.format(Date(usageStats.firstTimeStamp))
                val currentTotal = usageMap.getOrDefault(date, 0L)
                usageMap[date] = currentTotal + usageStats.totalTimeInForeground
            }
        }

        return usageMap
    }

    private fun getWeeklyUsage(): Map<String, List<Long>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_MONTH, -6)
        val startTime = calendar.timeInMillis

        val usageStatsList =
                usageStatsManager.queryUsageStats(
                        UsageStatsManager.INTERVAL_DAILY,
                        startTime,
                        endTime
                )

        val usageMap = mutableMapOf<String, MutableMap<String, Long>>() // date -> package -> usage
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())

        for (usageStats in usageStatsList) {
            val pkg = usageStats.packageName
            val date = dateFormat.format(Date(usageStats.firstTimeStamp))

            if (!usageMap.containsKey(date)) {
                usageMap[date] = mutableMapOf()
            }

            val currentUsage = usageMap[date]?.getOrDefault(pkg, 0L) ?: 0L
            usageMap[date]?.set(pkg, currentUsage + usageStats.totalTimeInForeground)
        }

        // Convert to format: Map<String, List<Long>>
        val resultMap = mutableMapOf<String, List<Long>>()
        for ((date, appUsages) in usageMap) {
            resultMap[date] = appUsages.values.toList()
        }

        return resultMap
    }
}
