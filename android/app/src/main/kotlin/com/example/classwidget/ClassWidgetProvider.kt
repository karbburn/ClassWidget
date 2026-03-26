package com.example.classwidget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.RemoteViews
import android.widget.Toast
import com.example.classwidget.R
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class ClassWidgetProvider : AppWidgetProvider() {
 
    companion object {
        const val ACTION_COMPLETE_TASK = "com.example.classwidget.ACTION_COMPLETE_TASK"
        const val ACTION_OPEN_APP = "com.example.classwidget.ACTION_OPEN_APP"
        const val ACTION_MIDNIGHT_REFRESH = "com.example.classwidget.ACTION_MIDNIGHT_REFRESH"
        const val ACTION_MINUTE_TICK = "com.example.classwidget.ACTION_MINUTE_TICK"
        const val EXTRA_TASK_ID = "extra_task_id"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("ClassWidget", "onReceive: ${intent.action}")
        when (intent.action) {
            ACTION_COMPLETE_TASK -> {
                val taskId = intent.getIntExtra(EXTRA_TASK_ID, -1)
                if (taskId != -1) {
                    updateTaskCompletion(context, taskId)
                }
            }
            ACTION_OPEN_APP -> {
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(launchIntent)
                }
            }
            ACTION_MIDNIGHT_REFRESH,
            ACTION_MINUTE_TICK,
            "com.example.classwidget.ACTION_BOOT",
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val thisWidget = android.content.ComponentName(context, ClassWidgetProvider::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
                
                // Reschedule alarms to ensure they keep firing
                scheduleMidnightAlarm(context)
                scheduleMinuteTickAlarm(context)

                // Trigger Flutter background sync for fresh data if needed
                try {
                    HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        Uri.parse("homeWidget://update")
                    ).send()
                } catch (e: Exception) {
                    Log.e("ClassWidget", "Background sync trigger failed", e)
                }
                
                // Force the ListView to re-read and re-filter data by new system date
                appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_list_view)
                for (appWidgetId in appWidgetIds) {
                    val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
                    updateAppWidget(context, appWidgetManager, appWidgetId, options)
                }
            }
        }
        super.onReceive(context, intent)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        // Schedule alarms when user first adds a widget
        scheduleMidnightAlarm(context)
        scheduleMinuteTickAlarm(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // Cancel all alarms when the last widget is removed
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        val midnightIntent = PendingIntent.getBroadcast(
            context, 9999,
            Intent(context, ClassWidgetProvider::class.java).apply { action = ACTION_MIDNIGHT_REFRESH },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(midnightIntent)

        val minuteIntent = PendingIntent.getBroadcast(
            context, 9998,
            Intent(context, ClassWidgetProvider::class.java).apply { action = ACTION_MINUTE_TICK },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(minuteIntent)
    }

    private fun updateTaskCompletion(context: Context, taskId: Int) {
        var db: android.database.sqlite.SQLiteDatabase? = null
        try {
            val dbPath = context.getDatabasePath("class_widget_v2.db").absolutePath
            db = android.database.sqlite.SQLiteDatabase.openDatabase(dbPath, null, android.database.sqlite.SQLiteDatabase.OPEN_READWRITE)
            val values = ContentValues().apply { put("completed", 1) }
            db.update("events", values, "id = ?", arrayOf(taskId.toString()))

            // Update JSON Cache in SharedPreferences so the list UI updates immediately
            val widgetData = HomeWidgetPlugin.getData(context)
            val jsonString = widgetData.getString(AppConstants.KEY_SCHEDULE_DATA, null)
            if (jsonString != null) {
                val jsonObject = JSONObject(jsonString)
                val events = jsonObject.optJSONArray(AppConstants.KEY_EVENTS)
                if (events != null) {
                    val newEvents = JSONArray()
                    for (i in 0 until events.length()) {
                        val event = events.getJSONObject(i)
                        if (event.optInt(AppConstants.KEY_ID) != taskId) {
                            newEvents.put(event)
                        }
                    }
                    jsonObject.put(AppConstants.KEY_EVENTS, newEvents)
                    
                    val editor = widgetData.edit()
                    editor.putString(AppConstants.KEY_SCHEDULE_DATA, jsonObject.toString())
                    editor.apply()
                }
            }

            Handler(Looper.getMainLooper()).post {
                Toast.makeText(context, "Task marked as completed!", Toast.LENGTH_SHORT).show()
            }

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = android.content.ComponentName(context, ClassWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_list_view)
            onUpdate(context, appWidgetManager, appWidgetIds)
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            db?.close()
        }
    }


    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            updateAppWidget(context, appWidgetManager, appWidgetId, options)
        }
        // CRITICAL: Force ListView to re-read data on EVERY update cycle.
        // Without this, the RemoteViewsFactory uses stale cached data.
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_list_view)

        // Ensure alarms are always scheduled
        scheduleMidnightAlarm(context)
        scheduleMinuteTickAlarm(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        updateAppWidget(context, appWidgetManager, appWidgetId, newOptions)
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        options: Bundle
    ) {
        Log.d("ClassWidget", "updateAppWidget: id=$appWidgetId")
        val widgetData = HomeWidgetPlugin.getData(context)
        val jsonString = widgetData.getString(AppConstants.KEY_SCHEDULE_DATA, "{}")
        
        // Always derive "today" from system clock
        val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val currentDayName = SimpleDateFormat("EEEE", Locale.getDefault()).format(Date())
        val currentTime = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())

        // Filter events for today
        var todayEvents = JSONArray()
        var showProfessorNames = true

        try {
            val jsonObject = JSONObject(jsonString)
            showProfessorNames = jsonObject.optBoolean(AppConstants.KEY_SHOW_PROFESSOR_NAMES, true)
            val allEvents = jsonObject.optJSONArray(AppConstants.KEY_EVENTS) ?: JSONArray()
            
            for (i in 0 until allEvents.length()) {
                val event = allEvents.getJSONObject(i)
                val eventDate = event.optString(AppConstants.KEY_DATE, "")
                if (eventDate == todayStr) {
                    val type = event.optString(AppConstants.KEY_TYPE, "class")
                    val completed = event.optBoolean(AppConstants.KEY_COMPLETED, false)
                    if (type == "class" || !completed) {
                        todayEvents.put(event)
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        val isEmpty = todayEvents.length() == 0

        // Find next upcoming class using system time
        var nextTitle = ""
        var minutesUntilNext = -1
        try {
            val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
            val nowParsed = timeFormat.parse(currentTime)
            
            for (i in 0 until todayEvents.length()) {
                val event = todayEvents.getJSONObject(i)
                val startTime = event.optString(AppConstants.KEY_START_TIME, "")
                if (startTime.isNotEmpty()) {
                    val nextParsed = timeFormat.parse(startTime)
                    if (nowParsed != null && nextParsed != null && nextParsed.after(nowParsed)) {
                        minutesUntilNext = ((nextParsed.time - nowParsed.time) / 60000).toInt()
                        nextTitle = event.optString(AppConstants.KEY_TITLE, "")
                        break
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Determine layout based on dimensions
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)

        val layoutId = when {
            minWidth < 150 || minHeight < 110 -> R.layout.widget_layout_small
            minWidth > 250 && minHeight > 250 -> R.layout.widget_layout_large
            else -> R.layout.widget_layout
        }

        val views = RemoteViews(context.packageName, layoutId)
        
        views.setTextViewText(R.id.widget_title, "ClassWidget · $currentDayName")

        if (isEmpty) {
            views.setViewVisibility(R.id.empty_view, android.view.View.VISIBLE)
            views.setViewVisibility(R.id.widget_list_view, android.view.View.GONE)
            views.setViewVisibility(R.id.next_class_container, android.view.View.GONE)
        } else {
            views.setViewVisibility(R.id.empty_view, android.view.View.GONE)
            views.setViewVisibility(R.id.widget_list_view, android.view.View.VISIBLE)
            
            // Handle Next Class countdown
            if (minutesUntilNext >= 0) {
                views.setViewVisibility(R.id.next_class_container, android.view.View.VISIBLE)
                val timeStr = if (minutesUntilNext > 60) {
                    "${minutesUntilNext / 60}h ${minutesUntilNext % 60}m"
                } else {
                    "${minutesUntilNext}m"
                }
                views.setTextViewText(R.id.next_class_text, "Next: $nextTitle in $timeStr")
            } else {
                views.setViewVisibility(R.id.next_class_container, android.view.View.GONE)
            }

            // Set up ListView
            val intent = Intent(context, ListRemoteViewsService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.widget_list_view, intent)
            views.setEmptyView(R.id.widget_list_view, R.id.empty_view)

            val baseIntent = Intent(context, ClassWidgetProvider::class.java)
            val basePendingIntent = PendingIntent.getBroadcast(
                context, 1000 + appWidgetId, baseIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setPendingIntentTemplate(R.id.widget_list_view, basePendingIntent)
        }

        // Tap to open app
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * Schedules an AlarmManager alarm at 00:00:01 the next day.
     * This guarantees the widget refreshes at midnight even if
     * DATE_CHANGED broadcast is suppressed by Doze mode.
     */
    private fun scheduleMidnightAlarm(context: Context) {
        Log.d("ClassWidget", "scheduleMidnightAlarm: scheduling for next midnight")
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(context, ClassWidgetProvider::class.java).apply {
            action = ACTION_MIDNIGHT_REFRESH
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            9999, // Unique request code for midnight alarm
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Calculate next midnight + 1 second
        val midnight = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 1)
            set(Calendar.MILLISECOND, 0)
        }

        alarmManager.setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            midnight.timeInMillis,
            pendingIntent
        )
    }

    /**
     * Schedules a repeating alarm that fires every ~60 seconds.
     * This keeps the "Next class in ___" countdown fresh.
     * Uses setAndAllowWhileIdle which Android may throttle during Doze
     * (every ~9 min), but will update reliably when the screen is on.
     */
    private fun scheduleMinuteTickAlarm(context: Context) {
        Log.d("ClassWidget", "scheduleMinuteTickAlarm: scheduling next tick")
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(context, ClassWidgetProvider::class.java).apply {
            action = ACTION_MINUTE_TICK
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            9998, // Unique request code for minute tick
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Fire 60 seconds from now
        val nextTick = System.currentTimeMillis() + 60_000L

        alarmManager.setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            nextTick,
            pendingIntent
        )
    }
}
